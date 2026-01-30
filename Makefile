# APHELION Gaming Hub
# Build targets for the gaming portal

.PHONY: build clean dev help

# Default target
all: build

# Build the distributable HTML file
build:
	@chmod +x scripts/build.sh
	@scripts/build.sh

# Remove build artifacts
clean:
	@rm -rf dist
	@echo "Cleaned dist/"

# Start a local dev server (requires python3)
dev: build
	@echo "Serving at http://localhost:8085"
	@cd dist && python3 -m http.server 8085

# Show available targets
help:
	@echo "APHELION Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make build   Build dist/index.html from src + config"
	@echo "  make clean   Remove dist directory"
	@echo "  make dev     Build and serve locally on :8080"
	@echo "  make help    Show this message"
