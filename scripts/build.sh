#!/usr/bin/env bash
# Thin wrapper: delegates to cross-platform build.py (reused by Makefile and build.cmd).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/build.py" "$@"
