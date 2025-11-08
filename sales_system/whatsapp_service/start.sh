#!/bin/bash

# WhatsApp Service Start Script

echo "🚀 Starting WhatsApp Auto Service..."
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "⚠️  Dependencies not installed. Running setup..."
    ./setup.sh
    echo ""
fi

# Start the service
echo "📱 Starting service on http://localhost:3001"
echo "   Press Ctrl+C to stop"
echo ""

node server.js





