const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { Pool } = require('pg');
const config = require('./config');

const app = express();
const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || 'localhost'; // Use '0.0.0.0' for network access

// Initialize Neon PostgreSQL Pool
const pool = new Pool(config.postgres);

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Optional: API Key authentication for network access
const API_KEY = process.env.API_KEY || null;
const requireAuth = (req, res, next) => {
  if (HOST === 'localhost' || HOST === '127.0.0.1') {
    return next();
  }
  
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
      const pendingRepliesResult = await pool.query(
        "SELECT * FROM whatsapp_replies WHERE processed = false ORDER BY received_at ASC"
      );
      const pendingReplies = pendingRepliesResult.rows;

      if (pendingReplies && pendingReplies.length > 0) {
        console.log(`📬 Found ${pendingReplies.length} pending replies, processing...`);
        for (const reply of pendingReplies) {
          try {
            const originalMessageResult = await pool.query(
              "SELECT sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id FROM whatsapp_messages WHERE client_phone = $1 ORDER BY sent_at DESC LIMIT 1",
              [reply.client_phone]
            );
            const originalMessage = originalMessageResult.rows[0] || null;

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
      if (message.from === 'status@broadcast') {
        return;
      }

      const from = message.from;
      const body = message.body;
      const timestamp = message.timestamp;
      const messageId = message.id._serialized;
      const isGroup = message.from.includes('@g.us');
      
      if (isGroup) {
        console.log('📨 Group message received, skipping...');
        return;
      }

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

      if (global.incomingMessages.length > 1000) {
        global.incomingMessages = global.incomingMessages.slice(-1000);
      }

      // Store in Neon Postgres
      try {
        const originalMessageResult = await pool.query(
          "SELECT sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id FROM whatsapp_messages WHERE client_phone = $1 ORDER BY sent_at DESC LIMIT 1",
          [phoneNumber]
        );
        const originalMessage = originalMessageResult.rows[0] || null;

        const replyResult = await pool.query(
          `INSERT INTO whatsapp_replies (
            reply_id, client_phone, message_content, received_at, 
            original_message_id, processed, auto_reply_sent, contact_forwarded
          ) VALUES ($1, $2, $3, $4, $5, false, false, false) RETURNING *`,
          [
            messageId,
            phoneNumber,
            body,
            new Date(timestamp * 1000).toISOString(),
            originalMessage?.message_id || null
          ]
        );
        const replyData = replyResult.rows[0];

        console.log('✅ Reply stored in Neon database');
        await processReply(replyData, originalMessage, phoneNumber);
      } catch (dbError) {
        console.error('❌ Database error:', dbError);
      }
    } catch (error) {
      console.error('❌ Error handling incoming message:', error);
    }
  });

  // Process reply: send auto-reply and forward contact
  async function processReply(replyData, originalMessage, phoneNumber) {
    try {
      if (!replyData.auto_reply_sent && clientReady) {
        try {
          const chatId = `${phoneNumber}@c.us`;
          const autoReplyText = config.autoReplyMessage;
          
          await client.sendMessage(chatId, autoReplyText);
          
          await pool.query(
            "UPDATE whatsapp_replies SET auto_reply_sent = true, auto_reply_sent_at = NOW() WHERE id = $1",
            [replyData.id]
          );

          console.log(`✅ Auto-reply sent to ${phoneNumber}`);
        } catch (autoReplyError) {
          console.error('❌ Error sending auto-reply:', autoReplyError);
        }
      }

      if (originalMessage && originalMessage.sent_by_machine_id && !replyData.contact_forwarded) {
        try {
          const contactResult = await pool.query(
            `INSERT INTO whatsapp_contacts (
              client_phone, forwarded_to_machine_id, forwarded_to_user_id, forwarded_to_user_name, acknowledged, conversation_started, forwarded_at
            ) VALUES ($1, $2, $3, $4, false, false, NOW()) RETURNING *`,
            [
              phoneNumber,
              originalMessage.sent_by_machine_id,
              originalMessage.sent_by_user_id,
              originalMessage.sent_by_user_name
            ]
          );
          const contactData = contactResult.rows[0];

          await pool.query(
            `UPDATE whatsapp_replies 
             SET contact_forwarded = true, 
                 forwarded_to_machine_id = $1, 
                 forwarded_at = NOW(), 
                 processed = true 
             WHERE id = $2`,
            [originalMessage.sent_by_machine_id, replyData.id]
          );

          console.log(`✅ Contact forwarded to ${originalMessage.sent_by_machine_id}`);
        } catch (forwardError) {
          console.error('❌ Error forwarding contact:', forwardError);
        }
      }
    } catch (error) {
      console.error('❌ Error processing reply:', error);
    }
  }

  client.initialize();
}

if (!global.incomingMessages) {
  global.incomingMessages = [];
}

// API Routes

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

app.get('/api/status', requireAuth, (req, res) => {
  res.json({
    success: true,
    status: clientStatus,
    ready: clientReady,
    hasQR: qrCodeData !== null
  });
});

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

    const formattedNumber = phoneNumber.replace(/\D/g, '');
    let numberWithCountryCode = formattedNumber;
    if (formattedNumber.startsWith('0')) {
      numberWithCountryCode = '256' + formattedNumber.substring(1);
    } else if (!formattedNumber.startsWith('256')) {
      numberWithCountryCode = '256' + formattedNumber;
    }

    const chatId = `${numberWithCountryCode}@c.us`;
    console.log(`📤 Sending message to ${chatId}...`);

    const result = await client.sendMessage(chatId, message);
    console.log(`✅ Message sent successfully! Message ID: ${result.id._serialized}`);

    try {
      await pool.query(
        `INSERT INTO whatsapp_messages (
          message_id, client_phone, message_content, message_type, 
          sent_by_machine_id, sent_by_user_id, sent_by_user_name, sent_at, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'sent')`,
        [
          result.id._serialized,
          numberWithCountryCode,
          message,
          messageType || 'message',
          sentByMachineId || 'unknown',
          sentByUserId || null,
          sentByUserName || null,
          new Date(result.timestamp * 1000).toISOString()
        ]
      );
      console.log('✅ Message stored in Neon database');
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

    const formattedNumber = phoneNumber.replace(/\D/g, '');
    let numberWithCountryCode = formattedNumber;
    if (formattedNumber.startsWith('0')) {
      numberWithCountryCode = '256' + formattedNumber.substring(1);
    } else if (!formattedNumber.startsWith('256')) {
      numberWithCountryCode = '256' + formattedNumber;
    }

    const chatId = `${numberWithCountryCode}@c.us`;

    let media;
    // Check if mediaPath is a Base64 data URL
    if (mediaPath.startsWith('data:application/pdf;base64,')) {
      console.log('📄 Processing Base64 PDF attachment...');
      const base64Data = mediaPath.replace('data:application/pdf;base64,', '');
      media = new MessageMedia('application/pdf', base64Data, 'invoice.pdf');
    } else {
      if (!fs.existsSync(mediaPath)) {
        return res.status(400).json({
          success: false,
          error: 'Media file not found'
        });
      }
      media = MessageMedia.fromFilePath(mediaPath);
    }

    console.log(`📤 Sending media to ${chatId}...`);
    const result = await client.sendMessage(chatId, media, { caption: message || '' });
    console.log(`✅ Media sent successfully!`);

    try {
      await pool.query(
        `INSERT INTO whatsapp_messages (
          message_id, client_phone, message_content, message_type, 
          sent_by_machine_id, sent_by_user_id, sent_by_user_name, sent_at, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'sent')`,
        [
          result.id._serialized,
          numberWithCountryCode,
          message || '[Media attachment]',
          messageType || 'media',
          sentByMachineId || 'unknown',
          sentByUserId || null,
          sentByUserName || null,
          new Date(result.timestamp * 1000).toISOString()
        ]
      );
      console.log('✅ Message stored in Neon database');
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

app.post('/api/restart', async (req, res) => {
  try {
    console.log('🔄 Restarting WhatsApp client...');
    if (client) {
      await client.destroy();
    }
    
    clientReady = false;
    clientStatus = 'disconnected';
    qrCodeData = null;
    
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

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    status: 'running',
    whatsappStatus: clientStatus,
    ready: clientReady
  });
});

app.get('/api/messages', requireAuth, (req, res) => {
  try {
    const since = req.query.since ? parseInt(req.query.since) : 0;
    const limit = req.query.limit ? parseInt(req.query.limit) : 50;
    
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

app.get('/api/messages/:phoneNumber', requireAuth, (req, res) => {
  try {
    const phoneNumber = req.params.phoneNumber.replace(/\D/g, '');
    const since = req.query.since ? parseInt(req.query.since) : 0;
    const limit = req.query.limit ? parseInt(req.query.limit) : 50;
    
    let formattedNumber = phoneNumber;
    if (phoneNumber.startsWith('0')) {
      formattedNumber = '256' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('256')) {
      formattedNumber = '256' + phoneNumber;
    }
    
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

app.get('/api/messages/unread/count', requireAuth, (req, res) => {
  try {
    const since = req.query.since ? parseInt(req.query.since) : Date.now() - 86400000;
    
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

app.post('/api/process-pending-replies', requireAuth, async (req, res) => {
  try {
    const pendingRepliesResult = await pool.query(
      "SELECT * FROM whatsapp_replies WHERE processed = false ORDER BY received_at ASC"
    );
    const pendingReplies = pendingRepliesResult.rows;

    let processedCount = 0;
    let errorCount = 0;

    for (const reply of pendingReplies || []) {
      try {
        const originalMessageResult = await pool.query(
          "SELECT sent_by_machine_id, sent_by_user_id, sent_by_user_name, message_id FROM whatsapp_messages WHERE client_phone = $1 ORDER BY sent_at DESC LIMIT 1",
          [reply.client_phone]
        );
        const originalMessage = originalMessageResult.rows[0] || null;

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

process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down WhatsApp service...');
  if (client) {
    await client.destroy();
  }
  await pool.end();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down WhatsApp service...');
  if (client) {
    await client.destroy();
  }
  await pool.end();
  process.exit(0);
});
