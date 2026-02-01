# APHELION - Agent Guide

Instructions for AI agents working on this codebase.

## Overview

APHELION is a static gaming portal. Config-driven, single-file output, zero runtime dependencies.

## Architecture

```
config/games.json  →  scripts/build.py  →  dist/index.html
src/*.{html,css,js} ↗
```

Single build engine: `scripts/build.py` (Python 3, no deps). Wrappers: `build.sh` (Linux/macOS), `build.cmd` (Windows), Makefile. Same behavior on all platforms.

## Key Files

| File | Purpose |
|------|---------|
| `config/games.json` | Game catalog. Edit this to add/remove games. |
| `src/styles.css` | All styles. Uses CSS custom properties. |
| `src/app.js` | All logic. IIFE, vanilla JS, no deps. |
| `src/index.html` | Template with `__STYLES__` and `__SCRIPT__` placeholders. |
| `scripts/build.py` | **Build engine** (cross-platform). Reused by Makefile, build.sh, build.cmd. |
| `scripts/build.sh` | Thin wrapper: runs build.py (Linux/macOS). |
| `scripts/build.cmd` | Thin wrapper: runs build.py (Windows). |
| `scripts/dev.cmd` | Build then serve on :8085 (Windows; equivalent of `make dev`). |

## Common Tasks

### Add a game

1. Edit `config/games.json`, add entry to `games` array
2. Ensure category exists in `categories` array
3. Build: `make build` (Linux/macOS) or `python scripts\build.py` / `scripts\build.cmd` (Windows)

### Add a category

1. Add to `categories` array in `config/games.json`
2. Run `make build`

### Modify styles

1. Edit `src/styles.css`
2. Run `make build`

### Modify behavior

1. Edit `src/app.js`
2. The `CONFIG` object is injected at build time
3. Run `make build`

## Conventions

- **CSS**: BEM-lite naming, CSS custom properties for theming
- **JS**: Vanilla ES6+, IIFE pattern, no modules (single file output)
- **Config**: JSON, no comments, keep it flat

## Build System (cross-platform)

**Single engine:** `scripts/build.py` (Python 3 stdlib only). Reused by all entry points.

| Platform | Build | Clean | Dev server |
|----------|--------|--------|------------|
| Linux/macOS | `make build` or `./scripts/build.sh` or `python3 scripts/build.py` | `make clean` or `rm -rf dist` | `make dev` or build then `cd dist && python3 -m http.server 8085` |
| Windows | `python scripts\build.py` or `scripts\build.cmd` | `rmdir /s /q dist` | `scripts\dev.cmd` or build then `cd dist && python -m http.server 8085` |

Makefile targets (when `make` is available): `build`, `clean`, `dev`, `help`.

## Testing Changes

```bash
# Linux/macOS
make dev
# Windows (from repo root)
python scripts\build.py && cd dist && python -m http.server 8085
# Open http://localhost:8085 in browser
```

## Constraints

- Output must be a single HTML file
- No external runtime dependencies beyond Python 3 (stdlib only)
- Keep JS under 200 lines
- Keep CSS under 400 lines
