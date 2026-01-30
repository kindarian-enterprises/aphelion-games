#!/usr/bin/env bash
# APHELION Build Script
# Combines src files and injects config into a single distributable HTML file.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src"
CONFIG="$ROOT/config/games.json"
DIST="$ROOT/dist"
OUT="$DIST/index.html"

mkdir -p "$DIST"

# Compact config JSON (single line)
CONFIG_JSON=$(tr -d '\n' < "$CONFIG" | sed 's/  */ /g')

# Inject config into JS, write to temp
TMPJS=$(mktemp)
sed "s|__APHELION_CONFIG__|$CONFIG_JSON|" "$SRC/app.js" > "$TMPJS"

# Build output: manually concatenate sections
{
  # Everything before __STYLES__
  sed -n '1,/__STYLES__/{ /__STYLES__/!p }' "$SRC/index.html"

  # CSS content
  cat "$SRC/styles.css"

  # Between __STYLES__ and __SCRIPT__
  sed -n '/__STYLES__/,/__SCRIPT__/{ /__STYLES__/!{ /__SCRIPT__/!p } }' "$SRC/index.html"

  # JS content (with config injected)
  cat "$TMPJS"

  # Everything after __SCRIPT__
  sed -n '/__SCRIPT__/,${  /__SCRIPT__/!p }' "$SRC/index.html"
} > "$OUT"

rm -f "$TMPJS"

echo "Built: $OUT"
echo "Size: $(wc -c < "$OUT" | tr -d ' ') bytes"
