#!/usr/bin/env bash
# Render every *.card.html to a 2400x1260 PNG (1200x630 @2x) in static/images/social/.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build ../static/images/social
for src in *.card.html; do
  name="${src%.card.html}"; out="build/$name.html"
  python3 - "$src" "$out" <<'PY'
import sys
src, out = sys.argv[1:]
html = open(src).read()
html = html.replace("<!--HEX-->", open("../linkedin-carousel/_hex.svg.frag").read())
html = html.replace("<!--TOP-->", open("_top.frag").read())
open(out, "w").write(html)
PY
  google-chrome --headless=new --hide-scrollbars --window-size=1200,630 --force-device-scale-factor=2 \
    --screenshot="../static/images/social/$name.png" "file://$PWD/$out" 2>/dev/null
  python3 - "../static/images/social/$name.png" <<'PY'
import sys, os
from PIL import Image
p = sys.argv[1]
im = Image.open(p).convert("RGB"); im.save(p, optimize=True)
print(f"{p}: {im.size[0]}x{im.size[1]}, {os.path.getsize(p)//1024} KB")
PY
done
