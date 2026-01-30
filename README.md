# APHELION

A config-driven gaming portal. Single HTML output, no runtime dependencies.

## Quick Start

```bash
make build    # creates dist/index.html
make dev      # builds and serves on localhost:8085
```

## Structure

```
aphelion/
├── config/
│   └── games.json      # Game catalog + categories
├── src/
│   ├── index.html      # HTML template
│   ├── styles.css      # Stylesheet
│   └── app.js          # Application logic
├── scripts/
│   └── build.sh        # Build script
├── dist/               # Build output (gitignored)
├── Makefile
└── README.md
```

## Adding Games

Edit `config/games.json`:

```json
{
  "id": "unique-slug",
  "title": "Game Title",
  "category": "arcade",
  "url": "https://example.com/game",
  "thumb": "https://example.com/thumb.png"
}
```

Categories must match an entry in the `categories` array.

Then run `make build`.

## Features

- Search (Ctrl+K)
- Category filtering
- Favorites (localStorage)
- Recently played tracking
- Embedded game modal
- Open in new tab
- Keyboard shortcuts (Esc to close, F for fullscreen)
- Responsive design

## Build

The build process:
1. Reads `config/games.json`
2. Injects config into `src/app.js`
3. Inlines CSS and JS into `src/index.html`
4. Outputs single file to `dist/index.html`

No bundlers. No transpilers. Just shell.

## Deployment

Copy `dist/index.html` anywhere. Static hosting, local file, USB stick.
