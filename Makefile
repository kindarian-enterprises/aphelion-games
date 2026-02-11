# APHELION Gaming Hub — Linux/macOS (make) and Windows (see scripts/build.cmd)
# Single engine: scripts/build.py (reused by build.sh, build.cmd, and this Makefile)

IMAGE_NAME ?= aphelion
IMAGE_TAG  ?= latest

.PHONY: build clean dev docker-build docker-run docker-stop help

all: build

build:
	@python3 scripts/build.py

clean:
	@rm -rf dist
	@echo "Cleaned dist/"

dev: build
	@echo "Serving at http://localhost:8085"
	@cd dist && python3 -m http.server 8085

docker-build: build
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

docker-run: docker-build
	@echo "Serving at http://localhost:8085"
	docker run --rm -p 8085:8080 $(IMAGE_NAME):$(IMAGE_TAG)

docker-stop:
	@docker ps -q --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG) | xargs -r docker stop

help:
	@echo "APHELION Build System (cross-platform engine: scripts/build.py)"
	@echo ""
	@echo "  make build         Build dist/index.html from src + config"
	@echo "  make clean         Remove dist directory"
	@echo "  make dev           Build and serve on :8085"
	@echo "  make docker-build  Build container image"
	@echo "  make docker-run    Build and run container on :8080"
	@echo "  make docker-stop   Stop running container"
	@echo "  make help          Show this message"
	@echo ""
	@echo "Windows (no make): scripts\\build.cmd   scripts\\dev.cmd (build+serve)"
