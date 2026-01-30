# APHELION - Agent Guide

Instructions for AI agents working on this codebase.

## Overview

APHELION is a static gaming portal. Config-driven, single-file output, zero runtime dependencies.

## Architecture

```
config/games.json  →  scripts/build.sh  →  dist/index.html
src/*.{html,css,js} ↗
```

The build injects `games.json` as a JS object and inlines all assets into one HTML file.

## Key Files

| File | Purpose |
|------|---------|
| `config/games.json` | Game catalog. Edit this to add/remove games. |
| `src/styles.css` | All styles. Uses CSS custom properties. |
| `src/app.js` | All logic. IIFE, vanilla JS, no deps. |
| `src/index.html` | Template with `__STYLES__` and `__SCRIPT__` placeholders. |
| `scripts/build.sh` | Build script. Bash, uses sed for injection. |

## Common Tasks

### Add a game

1. Edit `config/games.json`, add entry to `games` array
2. Ensure category exists in `categories` array
3. Run `make build`

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

## Build System

Makefile targets:
- `make build` - Build `dist/index.html`
- `make clean` - Remove `dist/`
- `make dev` - Build + serve on `:8085`

The build script is pure bash. It uses:
- `cat` to read files
- `sed` for placeholder replacement
- No external tools required beyond coreutils

## Testing Changes

```bash
make dev
# Open http://localhost:8085 in browser
```

## Constraints

- Output must be a single HTML file
- No external runtime dependencies
- No build tools beyond bash + coreutils
- Keep JS under 200 lines
- Keep CSS under 400 lines
