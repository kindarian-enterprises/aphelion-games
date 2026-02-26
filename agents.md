# APHELION - Agent Guide

Instructions for AI agents working on this codebase.

## Overview

APHELION is a static gaming portal. Config-driven, single-file output, zero runtime dependencies. Containerized with nginx:alpine for AWS App Runner deployment.

## Architecture

```
config/games.json  →  scripts/build.py  →  dist/index.html
src/*.{html,css,js} ↗

Dockerfile (nginx:alpine, port 8080)
├── nginx.conf            → /etc/nginx/nginx.conf
├── proxy-common.conf     → /etc/nginx/proxy-common.conf
├── locations.d/*.conf    → /etc/nginx/locations.d/*.conf
└── dist/index.html       → /usr/share/nginx/html/index.html
```

Two layers: the **portal** (static HTML built from src + config) and the **proxy** (nginx reverse-proxy for external game sites via `locations.d/`).

## Key Files

| File | Purpose |
|------|---------|
| `config/games.json` | Game catalog. Edit this to add/remove games. `proxy: true` = iframe via nginx; omit = external fallback. |
| `src/styles.css` | All styles. Uses CSS custom properties. |
| `src/app.js` | All logic. IIFE, vanilla JS, no deps. Handles proxy/non-proxy game modal branching. |
| `src/index.html` | Template with `__STYLES__` and `__SCRIPT__` placeholders. |
| `scripts/build.py` | **Build engine** (cross-platform). Reused by Makefile, build.sh, build.cmd. |
| `scripts/build.sh` | Thin wrapper: runs build.py (Linux/macOS). |
| `scripts/build.cmd` | Thin wrapper: runs build.py (Windows). |
| `scripts/dev.cmd` | Build then serve on :8085 (Windows; equivalent of `make dev`). |
| `Dockerfile` | `nginx:alpine` image. Copies nginx.conf, proxy-common.conf, locations.d/, dist/index.html. Port 8080. |
| `nginx.conf` | Base server config. Serves portal at `/` with COOP/COEP, glob-includes `locations.d/*.conf`. Uses `resolver 8.8.8.8` for regex proxy_pass. |
| `proxy-common.conf` | **Single source of truth** for shared proxy directives: SSL SNI, header stripping, COOP/COEP injection, sub_filter config. |
| `locations.d/*.conf` | One file per proxied game site. Regex location, included into the server block. |
| `locations.d/_template.conf.example` | Copy this to create a new proxy route. Not included by nginx (not `.conf`). |

## Common Tasks

### Add a game to the portal

1. Edit `config/games.json`, add entry to `games` array
2. Ensure category exists in `categories` array
3. Set `"proxy": true` if the game will be proxied (requires a `.conf` in `locations.d/`)
4. Omit `proxy` or set `false` for games that can't be proxied (will show external-link fallback)
5. Build: `make build` (Linux/macOS) or `python scripts\build.py` / `scripts\build.cmd` (Windows)

### Add a reverse-proxy route for a game site

1. Copy `locations.d/_template.conf.example` to `locations.d/<game-id>.conf`
2. Replace placeholders: `<name>` = game id from games.json, `<domain>` = upstream host
3. Rebuild container: `make docker-build`

**CRITICAL: The filename MUST match the game `id` in `games.json`** — the app constructs
iframe URLs as `/g/{id}{pathname}`. A mismatch means the route never matches.

**Per-game location file (only the per-site values):**

```nginx
location ~ ^/g/<name>(/.*)$ {
    proxy_pass https://<domain>$1;
    proxy_set_header Host <domain>;
    proxy_set_header Referer https://<domain>$1;
    proxy_set_header Origin https://<domain>;

    include /etc/nginx/proxy-common.conf;
    sub_filter 'https://<domain>' '/g/<name>';
}
```

**How it works:**
- Regex `^/g/<name>(/.*)$` captures the path after the game prefix into `$1`
- `proxy_pass https://<domain>$1` forwards to the exact upstream path (no double-pathing)
- `proxy-common.conf` provides all shared directives (SNI, header stripping, COOP/COEP, sub_filter config)
- `sub_filter` rewrites the upstream domain to `/g/<name>` so absolute URLs route back through the proxy
- `resolver 8.8.8.8` in nginx.conf is required because regex captures in proxy_pass need runtime DNS

**Naming convention:** filename = game id from games.json, e.g. `tetris.conf`, `buckshotroulette.conf`.

### Remove a proxy route

Delete the `.conf` file from `locations.d/` and rebuild.

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

## Container Architecture

- **Base image:** `nginx:alpine`
- **Port:** 8080 (AWS App Runner default)
- **Single process:** nginx foreground (`daemon off`), no supervisor
- **Static content:** `dist/index.html` → `/usr/share/nginx/html/index.html`
- **Shared proxy config:** `proxy-common.conf` → `/etc/nginx/proxy-common.conf`
- **Per-game proxy config:** `locations.d/*.conf` → `/etc/nginx/locations.d/*.conf`
- **Temp paths** in `/tmp/` for non-root operation
- **DNS resolver:** `8.8.8.8` (required for regex proxy_pass with captures)

### Cross-Origin Isolation

The portal and proxy use a layered COOP/COEP strategy so Wasm games get `SharedArrayBuffer`:

| Layer | COOP | COEP | Why |
|-------|------|------|-----|
| Portal (`/`) | `same-origin` | `credentialless` | Enables isolation without blocking external thumbnails |
| Proxy (`/g/*`) | `same-origin` | `require-corp` | Full isolation; all content is same-origin via proxy |

Headers stripped from upstream: `X-Frame-Options`, `Content-Security-Policy`, `Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy` (replaced by our own).

### Proxy Mechanics

- **Regex locations** (`~ ^/g/<name>(/.*)$`) capture the request path into `$1`
- **`proxy_pass https://<domain>$1`** maps directly to the upstream — no prefix appending
- **`sub_filter`** rewrites `https://<domain>` → `/g/<name>` in HTML/CSS/JS responses
- **`Accept-Encoding ""`** disables upstream gzip so sub_filter can rewrite the body
- **`Referer`/`Origin`** headers are spoofed toward the upstream domain

### Game Loading Logic (app.js)

The `openGame()` function handles two paths based on the `proxy` flag:

```javascript
if (game.proxy) {
  // Proxied: load in iframe through nginx reverse proxy
  el.frame.style.display = '';
  el.modalExternal.style.display = 'none';
  el.frame.src = '/g/' + game.id + new URL(game.url).pathname;
} else {
  // Non-proxied: show fallback panel with "Open in New Tab" button
  el.frame.style.display = 'none';
  el.modalExternal.style.display = '';
  el.modalExternalLink.href = game.url;
}
```

**Proxied games** (`proxy: true`):
- Iframe `src` is constructed as `/g/{id}{pathname}` which routes through the nginx location block
- The game `id` selects the location block; the URL pathname maps to the upstream path
- Headers are stripped/injected by `proxy-common.conf` so the iframe loads without CORS issues

**Non-proxied games** (no `proxy` flag):
- The iframe is hidden and a styled fallback panel is shown instead
- Panel displays an external-link icon, "This game can't be embedded." message, and "Open in New Tab" button
- The button links directly to `game.url` with `target="_blank"`
- This handles sites (e.g. NYT Wordle) that send `X-Frame-Options: DENY` or have complex CORS requirements that can't be satisfied by simple `sub_filter` rewriting

**HTML structure** (in `src/index.html`, inside `.modal-body`):
```html
<iframe class="game-frame" id="frame" ...></iframe>           <!-- proxied games -->
<div class="modal-external" id="modal-external" ...>          <!-- non-proxied fallback -->
  <div class="modal-external-content">
    <svg><!-- external link icon --></svg>
    <p>This game can't be embedded.</p>
    <a id="modal-external-link" href="" target="_blank">Open in New Tab</a>
  </div>
</div>
```

"Open in new tab" buttons on game cards still use `game.url` directly for all games.

## Proxy vs Non-Proxy Decision

When adding a new game, decide whether it should be proxied:

| Proxy? | When to use | Example |
|--------|-------------|---------|
| **Yes** (`"proxy": true`) | Simple static game sites, GitHub Pages games, indie game hosts | Tetris, Buckshot Roulette, Wordle Unlimited |
| **No** (omit flag) | Complex apps with many subdomains/APIs, strict CORS, or heavy JS that breaks under `sub_filter` rewriting | NYT Wordle, any site requiring login |

**Signs a site can't be proxied:**
- Makes API calls to multiple subdomains (each would need its own proxy route)
- Uses service workers that hardcode the origin
- Requires authentication / cookies scoped to the original domain
- Complex React/SPA that loads chunks from CDN paths `sub_filter` can't fully rewrite

**When in doubt:** try proxying first. If the game loads as the portal's `index.html` instead or hangs on a loading screen, it likely needs too many cross-domain resources to proxy cleanly. Remove the `.conf`, drop the `proxy` flag, rebuild.

## Conventions

- **CSS**: BEM-lite naming, CSS custom properties for theming
- **JS**: Vanilla ES6+, IIFE pattern, no modules (single file output)
- **Config**: JSON, no comments, keep it flat
- **Location files**: One `.conf` per game, filename = game slug, inside `locations.d/`
- **Proxy routes**: Always under `/g/` prefix

## Build System (cross-platform)

**Single engine:** `scripts/build.py` (Python 3 stdlib only). Reused by all entry points.

| Platform | Build | Clean | Dev server |
|----------|--------|--------|------------|
| Linux/macOS | `make build` or `./scripts/build.sh` or `python3 scripts/build.py` | `make clean` or `rm -rf dist` | `make dev` or build then `cd dist && python3 -m http.server 8085` |
| Windows | `python scripts\build.py` or `scripts\build.cmd` | `rmdir /s /q dist` | `scripts\dev.cmd` or build then `cd dist && python -m http.server 8085` |

Makefile targets: `build`, `clean`, `dev`, `docker-build`, `docker-run`, `docker-stop`, `help`.

## Testing Changes

```bash
# Portal only (local Python server)
make dev                    # http://localhost:8085

# Full container with proxy routes
make docker-run             # http://localhost:8080
```

## Constraints

- Output must be a single HTML file
- No external runtime dependencies beyond Python 3 (stdlib only)
- Keep JS under 300 lines
- Keep CSS under 1100 lines
- Location files: one `location` block per `.conf`, always under `/g/` prefix
- Dockerfile: nginx:alpine only, no multi-stage, no build tooling in image
