# APHELION Gaming Hub — Linux/macOS (make) and Windows (see scripts/build.cmd)
# Single engine: scripts/build.py (reused by build.sh, build.cmd, and this Makefile)

IMAGE_NAME ?= chronicleglados/aphelion
IMAGE_TAG  ?= latest

.PHONY: build clean dev docker-build docker-run docker-stop docker-test docker-publish deploy deploy-setup help

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

docker-test:
	@bash scripts/ci-local.sh

docker-publish:
	@bash scripts/ci-local.sh --push

deploy:
	@bash scripts/deploy-cloudrun.sh

deploy-setup:
	@bash scripts/setup-gcp-deploy.sh

help:
	@echo "APHELION Build System (cross-platform engine: scripts/build.py)"
	@echo ""
	@echo "  make build         Build dist/index.html from src + config"
	@echo "  make clean         Remove dist directory"
	@echo "  make dev           Build and serve on :8085"
	@echo "  make docker-build  Build container image"
	@echo "  make docker-run    Build and run container on :8080"
	@echo "  make docker-stop   Stop running container"
	@echo "  make docker-test   Build, run, and smoke-test container"
	@echo "  make docker-publish  Test and push to DockerHub"
	@echo "  make deploy        Deploy to Cloud Run (main only)"
	@echo "  make deploy-setup  Provision GCP SA and configure GitHub secrets"
	@echo "  make help          Show this message"
	@echo ""
	@echo "Windows (no make): scripts\\build.cmd   scripts\\dev.cmd (build+serve)"
