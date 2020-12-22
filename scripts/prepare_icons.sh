#!/usr/bin/env bash

set -e

OUT_DIR="${1}.iconset"
ICON_DIR=$(cd "$(dirname "$0")/.."; pwd)/VPNStatus/Assets.xcassets/AppIcon.appiconset

mkdir -p "$OUT_DIR"

make_icons() {
  size=$1
  size2x=$(( $1 * 2 ))
  if [ "$ICON_DIR"/icon_512x512@2x.png -nt "$OUT_DIR"/icon_${size}x${size}.png ]; then
    sips -Z $size "$ICON_DIR"/icon_512x512@2x.png -o "$OUT_DIR"/icon_${size}x${size}.png
    sips -Z $size2x "$ICON_DIR"/icon_512x512@2x.png -o "$OUT_DIR"/icon_${size}x${size}@2x.png
  fi
}

for size in 16 32 128 256 512; do
  make_icons $size
done

iconutil -c icns "$OUT_DIR"
rm -rf "$OUT_DIR"
