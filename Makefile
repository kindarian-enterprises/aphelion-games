# APHELION Gaming Hub — Linux/macOS (make) and Windows (see scripts/build.cmd)
# Single engine: scripts/build.py (reused by build.sh, build.cmd, and this Makefile)

.PHONY: build clean dev help

all: build

build:
	@python3 scripts/build.py

clean:
	@rm -rf dist
	@echo "Cleaned dist/"

dev: build
	@echo "Serving at http://localhost:8085"
	@cd dist && python3 -m http.server 8085

help:
	@echo "APHELION Build System (cross-platform engine: scripts/build.py)"
	@echo ""
	@echo "  make build   Build dist/index.html from src + config"
	@echo "  make clean   Remove dist directory"
	@echo "  make dev     Build and serve on :8085"
	@echo "  make help    Show this message"
	@echo ""
	@echo "Windows (no make): scripts\\build.cmd   scripts\\dev.cmd (build+serve)"
