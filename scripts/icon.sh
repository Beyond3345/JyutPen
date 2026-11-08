#!/bin/bash
# Exports src-tauri/icons/AppIcon.icon (Icon Composer; macOS 26 and later read it, with
# its light, dark, tinted and clear looks) for everything that cannot use it: the .icns of
# older macOS, the Windows .ico and the PNGs, made by `tauri icon` from the light icon on
# the 1024 px grid of macOS icons (824 px with a 100 px margin), and the light and dark
# marks of the window's header. Needs Icon Composer (on its own or inside Xcode).
set -euo pipefail
cd "$(dirname "$0")/.."
IC=$(ls "/Applications/Icon Composer.app/Contents/Executables/ictool" \
  "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" 2>/dev/null | head -1)
icons=src-tauri/icons
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export_png() { # rendition size file
  "$IC" $icons/AppIcon.icon --export-image --output-file "$3" --platform macOS \
    --rendition "$1" --width "$2" --height "$2" --scale 1 > /dev/null
}
export_png Default 824 "$tmp/light.png"
export_png Default 128 $icons/mark-light.png
export_png Dark 128 $icons/mark-dark.png
python3 - "$tmp/light.png" $icons/icon-source.png <<'EOF'
import sys
from PIL import Image
canvas = Image.new('RGBA', (1024, 1024))
canvas.alpha_composite(Image.open(sys.argv[1]).convert('RGBA'), (100, 100))
canvas.save(sys.argv[2])
EOF
npx tauri icon $icons/icon-source.png -o $icons > /dev/null 2>&1
rm -rf $icons/android $icons/ios
echo "icon: $icons/icon-source.png and the icons made from it, $icons/mark-light.png, $icons/mark-dark.png"
