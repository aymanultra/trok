#!/usr/bin/env bash
# Helper script to generate Trok Android launcher icons for all mipmap densities
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="${1:-$SCRIPT_DIR/assets/trok_icon.png}"
RES_DIR="$SCRIPT_DIR/android/app/src/main/res"

if [ ! -f "$ICON_SRC" ]; then
  echo "Icon source not found at: $ICON_SRC"
  echo "Usage: ./generate_icons.sh [path_to_source_icon.png]"
  exit 1
fi

echo "Generating Trok Android mipmap icons from $ICON_SRC..."

mkdir -p "$RES_DIR/mipmap-mdpi"
mkdir -p "$RES_DIR/mipmap-hdpi"
mkdir -p "$RES_DIR/mipmap-xhdpi"
mkdir -p "$RES_DIR/mipmap-xxhdpi"
mkdir -p "$RES_DIR/mipmap-xxxhdpi"

sips -s format png -z 48 48 "$ICON_SRC" --out "$RES_DIR/mipmap-mdpi/ic_launcher.png"
sips -s format png -z 72 72 "$ICON_SRC" --out "$RES_DIR/mipmap-hdpi/ic_launcher.png"
sips -s format png -z 96 96 "$ICON_SRC" --out "$RES_DIR/mipmap-xhdpi/ic_launcher.png"
sips -s format png -z 144 144 "$ICON_SRC" --out "$RES_DIR/mipmap-xxhdpi/ic_launcher.png"
sips -s format png -z 192 192 "$ICON_SRC" --out "$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"

echo "Trok launcher icons successfully generated in $RES_DIR/mipmap-*"
