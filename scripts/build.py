#!/usr/bin/env python3
"""
APHELION build script. Single cross-platform engine: combines src + config → dist/index.html.
Run from repo root or scripts/; no external deps. Reused by Makefile, build.sh, build.cmd.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

PLACEHOLDER_CONFIG = "__APHELION_CONFIG__"
MARKER_STYLES = "__STYLES__"
MARKER_SCRIPT = "__SCRIPT__"


def _root() -> Path:
    script_dir = Path(__file__).resolve().parent
    return script_dir.parent if script_dir.name == "scripts" else script_dir


def _compact_json(path: Path) -> str:
    data = json.loads(path.read_text(encoding="utf-8"))
    return json.dumps(data, separators=(",", ":"), ensure_ascii=False)


def build(root: Path | None = None) -> Path:
    root = root or _root()
    src = root / "src"
    config_path = root / "config" / "games.json"
    dist = root / "dist"
    out = dist / "index.html"

    dist.mkdir(parents=True, exist_ok=True)
    config_json = _compact_json(config_path)

    js_content = (src / "app.js").read_text(encoding="utf-8").replace(
        PLACEHOLDER_CONFIG, config_json
    )

    html = (src / "index.html").read_text(encoding="utf-8")
    css = (src / "styles.css").read_text(encoding="utf-8")

    before_styles, rest = html.split(MARKER_STYLES, 1)
    between_block, after_script = rest.split(MARKER_SCRIPT, 1)
    # between_block is "__STYLES__\n  </style>\n...\n  <script>\n"; keep only content between markers
    between = between_block.split(MARKER_STYLES, 1)[-1]

    out.write_text(
        before_styles + css + between + js_content + after_script,
        encoding="utf-8",
    )
    return out


def main() -> int:
    root = _root()
    out = build(root)
    size = out.stat().st_size
    print(f"Built: {out}")
    print(f"Size: {size} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
