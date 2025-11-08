const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

const app = express();
const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || 'localhost'; // Use '0.0.0.0' for network access

// Initialize Supabase client
const supabase = createClient(config.supabase.url, config.supabase.anonKey);

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Optional: API Key authentication for network access
const API_KEY = process.env.API_KEY || null;
const requireAuth = (req, res, next) => {
  if (HOST === 'localhost' || HOST === '127.0.0.1') {
    // Local access, no auth required
    return next();
  }
  
  // Network access, check API key
  if (API_KEY && req.headers['x-api-key'] !== API_KEY) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized. API key required for network access.'
    });
  }
  
  next();
};

// Store QR code and client state
let qrCodeData = null;
let clientReady = false;
let client = null;
let clientStatus = 'disconnected'; // disconnected, connecting, ready, error

// WhatsApp Client initialization
function initializeWhatsApp() {
  console.log('🚀 Initializing WhatsApp client...');
  
  client = new Client({
    authStrategy: new LocalAuth({
      dataPath: path.join(__dirname, '.wwebjs_auth')
    }),
    puppeteer: {
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--disable-gpu'
      ]
    }
  });

  // QR Code generation
  client.on('qr', (qr) => {
    console.log('📱 QR Code generated. Scan with your phone.');
    qrCodeData = qr;
    clientStatus = 'qr_ready';
    // Also print to terminal for easy scanning
    qrcode.generate(qr, { small: true });
  });

  // Client ready
  client.on('ready', async () => {
    console.log('✅ WhatsApp client is ready!');
    clientReady = true;
    clientStatus = 'ready';
    qrCodeData = null; // Clear QR code once ready
    
    // Process any pending replies when server comes online
    try {
      console.log('🔄 Checking for pending replies...');
      const { data: pendingReplies } = await supabase
        .from('whatsapp_replies')
        .select('*')
        .eq('processed', false)
        .order('received_at', { ascending: true });

      if (pendingReplies && pendingReplies.length > 0) {
        console.log(`📬 Found ${pendingReplies.length} pending replies, processing...`);
        for (const reply of pendingReplies) {
          try {
            const { data: originalMessage } = await supabase
              .from('whatsapp_messages')
              .select('sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id')
              .eq('client_phone', reply.client_phone)
              .order('sent_at', { ascending: false })
              .limit(1)
              .single();

            await processReply(reply, originalMessage, reply.client_phone);
          } catch (error) {
            console.error(`Error processing pending reply ${reply.id}:`, error);
          }
        }
        console.log('✅ Pending replies processed');
      }
    } catch (error) {
      console.error('⚠️ Error processing pending replies:', error);
    }
  });

  // Authentication
  client.on('authenticated', () => {
    console.log('🔐 WhatsApp authenticated successfully!');
    clientStatus = 'authenticated';
  });

  // Authentication failure
  client.on('auth_failure', (msg) => {
    console.error('❌ Authentication failed:', msg);
    clientStatus = 'error';
    clientReady = false;
  });

  // Client disconnected
  client.on('disconnected', (reason) => {
    console.log('🔌 WhatsApp client disconnected:', reason);
    clientReady = false;
    clientStatus = 'disconnected';
    
    // Try to reconnect after 5 seconds
    setTimeout(() => {
      if (clientStatus === 'disconnected') {
        console.log('🔄 Attempting to reconnect...');
        initializeWhatsApp();
      }
    }, 5000);
  });

  // Loading screen
  client.on('loading_screen', (percent, message) => {
    console.log(`⏳ Loading: ${percent}% - ${message}`);
    clientStatus = 'loading';
  });

  // Handle incoming messages (replies)
  client.on('message', async (message) => {
    try {
      // Skip messages from status (group/system messages)
      if (message.from === 'status@broadcast') {
        return;
      }

      // Get message details
      const from = message.from;
      const body = message.body;
      const timestamp = message.timestamp;
      const messageId = message.id._serialized;
      const isGroup = message.from.includes('@g.us');
      
      // Skip group messages if needed
      if (isGroup) {
        console.log('📨 Group message received, skipping...');
        return;
      }

      // Extract phone number (remove @c.us)
      const phoneNumber = from.replace('@c.us', '');

      console.log(`📨 Incoming message from ${phoneNumber}: ${body.substring(0, 50)}...`);

      // Store message in memory (backup)
      const incomingMessage = {
        id: messageId,
        from: phoneNumber,
        message: body,
        timestamp: timestamp,
        receivedAt: Date.now(),
      };

      if (!global.incomingMessages) {
        global.incomingMessages = [];
      }
      global.incomingMessages.push(incomingMessage);

      // Keep only last 1000 messages (prevent memory issues)
      if (global.incomingMessages.length > 1000) {
        global.incomingMessages = global.incomingMessages.slice(-1000);
      }

      // Store in Supabase database
      try {
        // Look up original message sender
        const { data: originalMessage, error: lookupError } = await supabase
          .from('whatsapp_messages')
          .select('sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id')
          .eq('client_phone', phoneNumber)
          .order('sent_at', { ascending: false })
          .limit(1)
          .single();

        // Store reply in database
        const { data: replyData, error: replyError } = await supabase
          .from('whatsapp_replies')
          .insert({
            reply_id: messageId,
            client_phone: phoneNumber,
            message_content: body,
            received_at: new Date(timestamp * 1000).toISOString(),
            original_message_id: originalMessage?.message_id || null,
            processed: false,
            auto_reply_sent: false,
            contact_forwarded: false,
          })
          .select()
          .single();

        if (replyError) {
          console.error('❌ Error storing reply in database:', replyError);
        } else {
          console.log('✅ Reply stored in database');

          // Process reply: auto-reply and forward contact
          await processReply(replyData, originalMessage, phoneNumber);
        }
      } catch (dbError) {
        console.error('❌ Database error:', dbError);
        // Continue even if database fails
      }

      console.log(`✅ Message processed. Total messages: ${global.incomingMessages.length}`);
    } catch (error) {
      console.error('❌ Error handling incoming message:', error);
    }
  });

  // Process reply: send auto-reply and forward contact
  async function processReply(replyData, originalMessage, phoneNumber) {
    try {
      // Send auto-reply
      if (!replyData.auto_reply_sent && clientReady) {
        try {
          const chatId = `${phoneNumber}@c.us`;
          const autoReplyText = config.autoReplyMessage;
          
          await client.sendMessage(chatId, autoReplyText);
          
          // Update database
          await supabase
            .from('whatsapp_replies')
            .update({
              auto_reply_sent: true,
              auto_reply_sent_at: new Date().toISOString(),
            })
            .eq('id', replyData.id);

          console.log(`✅ Auto-reply sent to ${phoneNumber}`);
        } catch (autoReplyError) {
          console.error('❌ Error sending auto-reply:', autoReplyError);
        }
      }

      // Forward contact to original sender
      if (originalMessage && originalMessage.sent_by_machine_id && !replyData.contact_forwarded) {
        try {
          // Store contact forwarding in database
          const { data: contactData, error: contactError } = await supabase
            .from('whatsapp_contacts')
            .insert({
              client_phone: phoneNumber,
              forwarded_to_machine_id: originalMessage.sent_by_machine_id,
              forwarded_to_user_id: originalMessage.sent_by_user_id,
              forwarded_to_user_name: originalMessage.sent_by_user_name,
              acknowledged: false,
              conversation_started: false,
            })
            .select()
            .single();

          if (contactError) {
            console.error('❌ Error forwarding contact:', contactError);
          } else {
            // Update reply record
            await supabase
              .from('whatsapp_replies')
              .update({
                contact_forwarded: true,
                forwarded_to_machine_id: originalMessage.sent_by_machine_id,
                forwarded_at: new Date().toISOString(),
                processed: true,
              })
              .eq('id', replyData.id);

            console.log(`✅ Contact forwarded to ${originalMessage.sent_by_machine_id}`);
          }
        } catch (forwardError) {
          console.error('❌ Error forwarding contact:', forwardError);
        }
      }
    } catch (error) {
      console.error('❌ Error processing reply:', error);
    }
  }

  // Initialize client
  client.initialize();
}

// Initialize messages store
if (!global.incomingMessages) {
  global.incomingMessages = [];
}

// API Routes

// Get QR code for initial setup
app.get('/api/qr', requireAuth, (req, res) => {
  if (qrCodeData) {
    res.json({
      success: true,
      qr: qrCodeData,
      status: 'qr_ready'
    });
  } else if (clientReady) {
    res.json({
      success: true,
      qr: null,
      status: 'ready',
      message: 'WhatsApp is already connected. No QR code needed.'
    });
  } else {
    res.json({
      success: false,
      qr: null,
      status: clientStatus,
      message: 'QR code not available yet. Please wait...'
    });
  }
});

// Get client status
app.get('/api/status', requireAuth, (req, res) => {
  res.json({
    success: true,
    status: clientStatus,
    ready: clientReady,
    hasQR: qrCodeData !== null
  });
});

// Send message
app.post('/api/send', requireAuth, async (req, res) => {
  try {
    if (!clientReady || !client) {
      return res.status(400).json({
        success: false,
        error: 'WhatsApp client is not ready. Please ensure WhatsApp is connected.'
      });
    }

    const { phoneNumber, message, messageType, sentByMachineId, sentByUserId, sentByUserName } = req.body;

    if (!phoneNumber || !message) {
      return res.status(400).json({
        success: false,
        error: 'Phone number and message are required'
      });
    }

    // Format phone number (remove any non-digit characters and ensure country code)
    const formattedNumber = phoneNumber.replace(/\D/g, '');
    
    // Add country code if not present (assuming Uganda +256)
    let numberWithCountryCode = formattedNumber;
    if (formattedNumber.startsWith('0')) {
      numberWithCountryCode = '256' + formattedNumber.substring(1);
    } else if (!formattedNumber.startsWith('256')) {
      numberWithCountryCode = '256' + formattedNumber;
    }

    // WhatsApp format: country code + number without +
    const chatId = `${numberWithCountryCode}@c.us`;

    console.log(`📤 Sending message to ${chatId}...`);

    // Send message
    const result = await client.sendMessage(chatId, message);

    console.log(`✅ Message sent successfully! Message ID: ${result.id._serialized}`);

    // Store message in Supabase database for tracking
    try {
      const { error: dbError } = await supabase
        .from('whatsapp_messages')
        .insert({
          message_id: result.id._serialized,
          client_phone: numberWithCountryCode,
          message_content: message,
          message_type: messageType || 'message',
          sent_by_machine_id: sentByMachineId || 'unknown',
          sent_by_user_id: sentByUserId || null,
          sent_by_user_name: sentByUserName || null,
          sent_at: new Date(result.timestamp * 1000).toISOString(),
          status: 'sent',
        });

      if (dbError) {
        console.error('⚠️ Error storing message in database:', dbError);
        // Continue even if database fails
      } else {
        console.log('✅ Message stored in database');
      }
    } catch (dbError) {
      console.error('⚠️ Database error (non-critical):', dbError);
    }

    res.json({
      success: true,
      messageId: result.id._serialized,
      timestamp: result.timestamp,
      message: 'Message sent successfully'
    });

  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to send message'
    });
  }
});

// Send message with media (PDF)
app.post('/api/send-media', requireAuth, async (req, res) => {
  try {
    if (!clientReady || !client) {
      return res.status(400).json({
        success: false,
        error: 'WhatsApp client is not ready. Please ensure WhatsApp is connected.'
      });
    }

    const { phoneNumber, message, mediaPath, messageType, sentByMachineId, sentByUserId, sentByUserName } = req.body;

    if (!phoneNumber || !mediaPath) {
      return res.status(400).json({
        success: false,
        error: 'Phone number and media path are required'
      });
    }

    // Format phone number
    const formattedNumber = phoneNumber.replace(/\D/g, '');
    let numberWithCountryCode = formattedNumber;
    if (formattedNumber.startsWith('0')) {
      numberWithCountryCode = '256' + formattedNumber.substring(1);
    } else if (!formattedNumber.startsWith('256')) {
      numberWithCountryCode = '256' + formattedNumber;
    }

    const chatId = `${numberWithCountryCode}@c.us`;

    // Check if file exists
    if (!fs.existsSync(mediaPath)) {
      return res.status(400).json({
        success: false,
        error: 'Media file not found'
      });
    }

    console.log(`📤 Sending media to ${chatId}...`);

      // Send media
      const media = MessageMedia.fromFilePath(mediaPath);
      const result = await client.sendMessage(chatId, media, { caption: message || '' });

      console.log(`✅ Media sent successfully!`);

      // Store message in Supabase database for tracking
      try {
        const { error: dbError } = await supabase
          .from('whatsapp_messages')
          .insert({
            message_id: result.id._serialized,
            client_phone: numberWithCountryCode,
            message_content: message || '[Media attachment]',
            message_type: messageType || 'media',
            sent_by_machine_id: sentByMachineId || 'unknown',
            sent_by_user_id: sentByUserId || null,
            sent_by_user_name: sentByUserName || null,
            sent_at: new Date(result.timestamp * 1000).toISOString(),
            status: 'sent',
          });

        if (dbError) {
          console.error('⚠️ Error storing message in database:', dbError);
        } else {
          console.log('✅ Message stored in database');
        }
      } catch (dbError) {
        console.error('⚠️ Database error (non-critical):', dbError);
      }

      res.json({
        success: true,
        messageId: result.id._serialized,
        message: 'Media sent successfully'
      });

  } catch (error) {
    console.error('❌ Error sending media:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to send media'
    });
  }
});

// Restart/Reinitialize client
app.post('/api/restart', async (req, res) => {
  try {
    console.log('🔄 Restarting WhatsApp client...');
    
    if (client) {
      await client.destroy();
    }
    
    clientReady = false;
    clientStatus = 'disconnected';
    qrCodeData = null;
    
    // Wait a bit before reinitializing
    setTimeout(() => {
      initializeWhatsApp();
    }, 2000);

    res.json({
      success: true,
      message: 'WhatsApp client restarting...'
    });
  } catch (error) {
    console.error('❌ Error restarting client:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    status: 'running',
    whatsappStatus: clientStatus,
    ready: clientReady
  });
});

// Get incoming messages (replies)
app.get('/api/messages', requireAuth, (req, res) => {
  try {
    const since = req.query.since ? parseInt(req.query.since) : 0;
    const limit = req.query.limit ? parseInt(req.query.limit) : 50;
    
    // Get messages since timestamp
    const messages = (global.incomingMessages || [])
      .filter(msg => msg.receivedAt > since)
      .sort((a, b) => b.receivedAt - a.receivedAt)
      .slice(0, limit);
    
    res.json({
      success: true,
      messages: messages,
      count: messages.length,
      latestTimestamp: messages.length > 0 ? messages[0].receivedAt : since
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get messages from specific phone number
app.get('/api/messages/:phoneNumber', requireAuth, (req, res) => {
  try {
    const phoneNumber = req.params.phoneNumber.replace(/\D/g, '');
    const since = req.query.since ? parseInt(req.query.since) : 0;
    const limit = req.query.limit ? parseInt(req.query.limit) : 50;
    
    // Format phone number for matching
    let formattedNumber = phoneNumber;
    if (phoneNumber.startsWith('0')) {
      formattedNumber = '256' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('256')) {
      formattedNumber = '256' + phoneNumber;
    }
    
    // Get messages from this phone number
    const messages = (global.incomingMessages || [])
      .filter(msg => msg.from === formattedNumber && msg.receivedAt > since)
      .sort((a, b) => b.receivedAt - a.receivedAt)
      .slice(0, limit);
    
    res.json({
      success: true,
      messages: messages,
      count: messages.length,
      phoneNumber: formattedNumber
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get unread message count
app.get('/api/messages/unread/count', requireAuth, (req, res) => {
  try {
    const since = req.query.since ? parseInt(req.query.since) : Date.now() - 86400000; // Last 24 hours
    
    const unreadCount = (global.incomingMessages || [])
      .filter(msg => msg.receivedAt > since)
      .length;
    
    res.json({
      success: true,
      count: unreadCount,
      since: since
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Process pending replies (call when server comes online)
app.post('/api/process-pending-replies', requireAuth, async (req, res) => {
  try {
    // Get all unprocessed replies
    const { data: pendingReplies, error: fetchError } = await supabase
      .from('whatsapp_replies')
      .select('*')
      .eq('processed', false)
      .order('received_at', { ascending: true });

    if (fetchError) {
      throw fetchError;
    }

    let processedCount = 0;
    let errorCount = 0;

    for (const reply of pendingReplies || []) {
      try {
        // Look up original message sender
        const { data: originalMessage } = await supabase
          .from('whatsapp_messages')
          .select('sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id')
          .eq('client_phone', reply.client_phone)
          .order('sent_at', { ascending: false })
          .limit(1)
          .single();

        // Process reply
        await processReply(reply, originalMessage, reply.client_phone);
        processedCount++;
      } catch (error) {
        console.error(`Error processing reply ${reply.id}:`, error);
        errorCount++;
      }
    }

    res.json({
      success: true,
      processed: processedCount,
      errors: errorCount,
      total: pendingReplies?.length || 0
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Start server
app.listen(PORT, HOST, () => {
  const accessUrl = HOST === '0.0.0.0' 
    ? `http://localhost:${PORT} (and network: http://<your-ip>:${PORT})`
    : `http://${HOST}:${PORT}`;
  
  console.log(`🚀 WhatsApp Service running on ${accessUrl}`);
  console.log(`📱 Initialize WhatsApp client...`);
  
  if (HOST === '0.0.0.0' && API_KEY) {
    console.log(`🔐 API Key authentication enabled for network access`);
  } else if (HOST === '0.0.0.0') {
    console.log(`⚠️  WARNING: Network access enabled without API key!`);
    console.log(`   Set API_KEY environment variable for security.`);
  }
  
  initializeWhatsApp();
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down WhatsApp service...');
  if (client) {
    await client.destroy();
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down WhatsApp service...');
  if (client) {
    await client.destroy();
  }
  process.exit(0);
});

