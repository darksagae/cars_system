#!/bin/bash
# NSB Motors - PocketBase Setup Script
# Run this ONCE on the master desktop PC

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PB_DIR="$SCRIPT_DIR/pocketbase"

echo "=== NSB Motors PocketBase Setup ==="

# Create pocketbase directory
mkdir -p "$PB_DIR/pb_public"

# Download PocketBase if not present
if [ ! -f "$PB_DIR/pocketbase" ]; then
  echo "Downloading PocketBase..."
  # Get latest version
  LATEST=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  VERSION="${LATEST#v}"

  # Detect arch
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    FILE="pocketbase_${VERSION}_linux_amd64.zip"
  else
    FILE="pocketbase_${VERSION}_linux_arm64.zip"
  fi

  curl -L -o /tmp/pb.zip "https://github.com/pocketbase/pocketbase/releases/download/${LATEST}/${FILE}"
  unzip -o /tmp/pb.zip -d "$PB_DIR"
  chmod +x "$PB_DIR/pocketbase"
  rm /tmp/pb.zip
  echo "PocketBase downloaded: $LATEST"
else
  echo "PocketBase already exists."
fi

# Copy web portal to pb_public
cp "$SCRIPT_DIR/pb_portal/index.html" "$PB_DIR/pb_public/index.html" 2>/dev/null || true

echo ""
echo "=== Starting PocketBase ==="
echo "Admin UI: http://localhost:8090/_/"
echo "API:      http://localhost:8090/"
echo ""
echo "On first run, visit http://localhost:8090/_ to create your admin account."
echo ""
echo "Press Ctrl+C to stop."
echo ""

cd "$PB_DIR"
./pocketbase serve --http="0.0.0.0:8090" --publicDir="./pb_public"
