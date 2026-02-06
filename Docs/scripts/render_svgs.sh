#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAM_DIR="$ROOT_DIR/diagrams"
ASSET_DIR="$ROOT_DIR/assets"

mkdir -p "$ASSET_DIR"

if [[ -x "$ROOT_DIR/../node_modules/.bin/mmdc" ]]; then
  MMDC=("$ROOT_DIR/../node_modules/.bin/mmdc")
elif command -v mmdc >/dev/null 2>&1; then
  MMDC=(mmdc)
else
  MMDC=(npx -y @mermaid-js/mermaid-cli)
fi

# Optional browser override for environments where mmdc cannot auto-find Chrome.
if [[ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]]; then
  if command -v google-chrome >/dev/null 2>&1; then
    export PUPPETEER_EXECUTABLE_PATH="$(command -v google-chrome)"
  elif command -v chromium >/dev/null 2>&1; then
    export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium)"
  elif command -v chromium-browser >/dev/null 2>&1; then
    export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium-browser)"
  fi
fi

for src in "$DIAGRAM_DIR"/*.mmd; do
  name="$(basename "$src" .mmd)"
  out="$ASSET_DIR/$name.svg"
  echo "Rendering $src -> $out"
  "${MMDC[@]}" -i "$src" -o "$out"
done

echo "Done. SVG files are in: $ASSET_DIR"
