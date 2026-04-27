#!/bin/bash
# Deploy UniFind to cPanel via SSH (direct streaming, no storage)
# Usage: ./deploy.sh

set -e

CPANEL_USER="ivanovs1"
CPANEL_HOST="cyan.csam.montclair.edu"
CPANEL_PATH="/home/ivanovs1/public_html/UniFind"
SSH_KEY="$HOME/.ssh/id_rsa"

echo "Building Flutter web..."
cd unifind_flutter
flutter clean
flutter build web --release --base-href /~ivanovs1/UniFind/

BUILD_DIR="$(pwd)/build/web"

echo ""
echo "Deploying to cPanel via SSH (streaming)..."
echo "  User: $CPANEL_USER"
echo "  Host: $CPANEL_HOST"
echo "  Path: $CPANEL_PATH"
echo ""

# Clear old files on cPanel
echo "Clearing old files on cPanel..."
ssh -i "$SSH_KEY" "$CPANEL_USER@$CPANEL_HOST" "rm -rf $CPANEL_PATH/*"

# Sync build files directly to cPanel (streaming, no local zip)
echo "Syncing build files to cPanel..."
rsync -avz \
  -e "ssh -i $SSH_KEY" \
  --delete \
  "$BUILD_DIR/" \
  "$CPANEL_USER@$CPANEL_HOST:$CPANEL_PATH/"

echo ""
echo "✓ Deployment complete!"
echo "Live at: http://cyan.csam.montclair.edu/~ivanovs1/Unifind/"
