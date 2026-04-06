#!/bin/bash
# Deploy UniFind to cPanel
# Usage: ./deploy.sh

set -e

echo "Building Flutter web..."
cd unifind_flutter
flutter clean
flutter build web --release --base-href /~ivanovs1/Unifind/

echo "Creating zip..."
cd build
rm -f web.zip
zip -r web.zip web/

echo ""
echo "Build complete! Upload this file to cPanel:"
echo "  $(pwd)/web.zip"
echo ""
echo "On cPanel (Unifind/ folder):"
echo "  1. Delete all old files"
echo "  2. Upload web.zip"
echo "  3. Extract"
echo "  4. Move files from web/ up to Unifind/"
echo "  5. Delete web/ folder and web.zip"
echo ""
echo "Live at: http://cyan.csam.montclair.edu/~ivanovs1/Unifind/"
