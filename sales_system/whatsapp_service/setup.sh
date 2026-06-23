#!/bin/bash

# WhatsApp Service Setup Script
# This script installs dependencies and sets up the WhatsApp service

echo "🚀 Setting up WhatsApp Auto Service..."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "❌ Node.js version 14 or higher is required!"
    echo "Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) is installed"
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed!"
    exit 1
fi

echo "✅ npm $(npm -v) is installed"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "To start the service, run:"
    echo "  npm start"
    echo ""
    echo "Or use the start script:"
    echo "  ./start.sh"
    echo ""
else
    echo ""
    echo "❌ Failed to install dependencies"
    exit 1
fi





