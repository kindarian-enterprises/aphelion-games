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
│   └── games.json               # Game catalog + categories
├── locations.d/                  # One .conf per proxied game site
│   ├── _template.conf.example   # Copy to add a new backend
│   ├── buckshotroullete.conf
│   ├── tetris.conf
│   └── wordleunlimited.conf
├── src/
│   ├── index.html               # HTML template
│   ├── styles.css               # Stylesheet
│   └── app.js                   # Application logic
├── scripts/
│   ├── build.py                 # Build engine (cross-platform)
│   ├── build.sh                 # Wrapper (Linux/macOS)
│   ├── build.cmd                # Wrapper (Windows)
│   └── dev.cmd                  # Build + serve (Windows)
├── dist/                        # Build output (gitignored)
├── Dockerfile                   # nginx:alpine, port 8080
├── nginx.conf                   # Base server config
├── proxy-common.conf            # Shared proxy directives
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
  "thumb": "https://example.com/thumb.png",
  "proxy": true
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | URL-safe slug. Must match `locations.d/<id>.conf` filename if proxied. |
| `title` | Yes | Display name. |
| `category` | Yes | Must match an entry in the `categories` array. |
| `url` | Yes | Upstream game URL. |
| `thumb` | Yes | Thumbnail image URL. |
| `proxy` | No | Set `true` to embed via reverse proxy. Omit or `false` for external-link fallback. |

### Proxied vs Non-Proxied Games

Games fall into two categories based on the `proxy` flag:

| Type | `proxy` flag | Modal behavior | Requires `.conf`? |
|------|-------------|----------------|-------------------|
| **Proxied** | `true` | Loads in iframe via `/g/{id}/...` | Yes |
| **Non-proxied** | omitted/`false` | Shows "Open in New Tab" fallback panel | No |

**Proxied games** are served through nginx reverse proxy, which strips
restrictive headers (`X-Frame-Options`, CSP) and injects COOP/COEP so the
game works inside the portal iframe. This requires a matching `.conf` file
in `locations.d/`.

**Non-proxied games** (sites that are too complex to proxy, e.g. NYT Wordle)
show a styled fallback panel in the modal with an "Open in New Tab" button.
No nginx configuration is needed.

Then run `make build`.

## Adding a Reverse-Proxy Route

External game sites are proxied through nginx so they can be embedded
without cross-origin issues. Each route is a single `.conf` file in
`locations.d/`.

1. Copy the template (filename **must** match the game `id` in `games.json`):

```bash
cp locations.d/_template.conf.example locations.d/my-game.conf
```

2. Fill in the values:

```nginx
# locations.d/my-game.conf
location ~ ^/g/my-game(/.*)$ {
    proxy_pass https://example.com$1;
    proxy_set_header Host example.com;
    proxy_set_header Referer https://example.com$1;
    proxy_set_header Origin https://example.com;

    include /etc/nginx/proxy-common.conf;
    sub_filter 'https://example.com' '/g/my-game';
}
```

3. Rebuild the container: `make docker-build`

How it works:
- Regex capture `$1` maps the request path directly to the upstream
- `proxy-common.conf` provides SNI, COOP/COEP, header stripping, sub_filter config
- `sub_filter` rewrites absolute URLs back through the proxy
- Portal uses `credentialless` COEP so Wasm games get `SharedArrayBuffer`

## Features

- Search (Ctrl+K)
- Category filtering
- Favorites (localStorage)
- Recently played tracking
- Embedded game modal (proxied games load in iframe)
- External fallback panel (non-proxied games get "Open in New Tab" button)
- Open in new tab (all game cards)
- Keyboard shortcuts (Esc to close, F for fullscreen)
- Cross-origin isolation (SharedArrayBuffer for Wasm games)
- Responsive design

## Build

The build process:
1. Reads `config/games.json`
2. Injects config into `src/app.js`
3. Inlines CSS and JS into `src/index.html`
4. Outputs single file to `dist/index.html`

No bundlers. No transpilers. Just Python stdlib.

## Deployment

### Static

Copy `dist/index.html` anywhere. Static hosting, local file, USB stick.

### Container (AWS App Runner)

```bash
make docker-build          # builds nginx:alpine image on port 8080
make docker-run            # build + run locally at http://localhost:8080
```

The Dockerfile uses `nginx:alpine` directly. `make docker-build` runs
the site build first, then copies `dist/index.html`, `nginx.conf`,
`proxy-common.conf`, and `locations.d/*.conf` into the image.

The base `nginx.conf` serves the portal at `/` and glob-includes
`locations.d/*.conf` for reverse-proxy routes. To add or remove a
proxied game site, add or delete a `.conf` file and rebuild.

### Game Loading Behavior

```
User clicks game card
        │
        ▼
  game.proxy === true ?
   ┌─────┴─────┐
  YES          NO
   │            │
   ▼            ▼
 iframe        Fallback panel
 /g/{id}/...   "Can't be embedded"
               + Open in New Tab btn
```

Non-proxied games cannot be embedded because the upstream sends
`X-Frame-Options: DENY` or strict CSP headers that nginx can't strip
without a proxy route. The fallback panel gives users a clean path to
open the game directly.
