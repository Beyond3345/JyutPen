#!/bin/bash
# Compiles src-tauri/icons/AppIcon.icon (Icon Composer) into src-tauri/icons/Assets.car,
# which the app bundle carries for macOS 26 and later (its light, dark, tinted and clear
# looks), and exports it for everything else: the .icns of older macOS, the Windows .ico
# and the PNGs, made by `tauri icon` from the light icon on the 1024 px grid of macOS
# icons (824 px with a 100 px margin), and the light and dark marks of the window's
# header. Needs Xcode 26 or later and Icon Composer (on its own or inside Xcode).
# The builds take Assets.car as it is: actool's server fails ("failed to run actool",
# "Bad file descriptor") when Tauri is the program that starts it.
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
# a fresh actool server: one left over from a failed run fails again
xcrun actool --quit-all-idle-servers > /dev/null 2>&1 || true
mkdir "$tmp/car"
xcrun actool $icons/AppIcon.icon --compile "$tmp/car" --output-format human-readable-text \
  --errors --app-icon AppIcon --include-all-app-icons --target-device mac \
  --minimum-deployment-target 13.3 --platform macosx \
  --output-partial-info-plist "$tmp/car/info.plist" > /dev/null
cp "$tmp/car/Assets.car" $icons/Assets.car
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
echo "icon: $icons/Assets.car, $icons/icon-source.png and the icons made from it, $icons/mark-light.png, $icons/mark-dark.png"
