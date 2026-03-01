# Makefile for Training Platform
# Supports: base image, tool-pack images, profile-based deployment, testing

# Image configuration
IMAGE_NAME ?= training-platform-base
IMAGE_TAG ?= v1.0.0
REGISTRY ?= image-registry.openshift-image-registry.svc:5000/devops
FULL_IMAGE = $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
CLUSTER_DOMAIN ?= $(error Set CLUSTER_DOMAIN=apps.your-cluster.example.com)

# Student configuration
PROFILE ?= devops-bootcamp
START ?= 1
END ?= 5

.PHONY: help build build-base build-tools build-all deploy deploy-profile \
        test test-profiles test-lint test-base-image \
        list-profiles status clean monitor

# ---- Help ----

help: ## Show this help message
	@echo "Training Platform - Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Common workflows:"
	@echo "  make build-base                          Build base image"
	@echo "  make test-profiles                       Validate all profiles"
	@echo "  make test-lint                            Lint all scripts"
	@echo "  make deploy-profile PROFILE=java-dev END=5  Deploy with profile"

# ---- Build ----

build-base: ## Build the base training platform image
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

build-tool-cloud-native: ## Build cloud-native tool-pack image
	docker build -t tool-pack-cloud-native:$(IMAGE_TAG) images/tool-packs/cloud-native/

build-tool-java: ## Build Java tool-pack image
	docker build -t tool-pack-java:$(IMAGE_TAG) images/tool-packs/java/

build-tool-nodejs: ## Build Node.js tool-pack image
	docker build -t tool-pack-nodejs:$(IMAGE_TAG) images/tool-packs/nodejs/

build-tool-python: ## Build Python tool-pack image
	docker build -t tool-pack-python:$(IMAGE_TAG) images/tool-packs/python/

build-tool-iac: ## Build IaC (Pulumi) tool-pack image
	docker build -t tool-pack-iac:$(IMAGE_TAG) images/tool-packs/iac/

build-tools: build-tool-cloud-native build-tool-java build-tool-nodejs build-tool-python build-tool-iac ## Build all tool-pack images

build-all: build-base build-tools ## Build base + all tool-pack images

build-monolith: ## Build the legacy monolith image
	docker build -f Dockerfile.monolith -t code-server-student:$(IMAGE_TAG) .

# ---- Deploy ----

deploy-profile: ## Deploy students with a profile (PROFILE=name START=1 END=5)
	./admin/deploy/deploy-profile.sh \
		--profile $(PROFILE) \
		--start $(START) \
		--end $(END) \
		--domain $(CLUSTER_DOMAIN)

deploy-profile-dry: ## Dry-run deploy (generate overlays without applying)
	./admin/deploy/deploy-profile.sh \
		--profile $(PROFILE) \
		--start $(START) \
		--end $(END) \
		--domain $(CLUSTER_DOMAIN) \
		--dry-run

deploy-legacy: ## Deploy using legacy OpenShift Template
	./admin/deploy/complete-student-setup-simple.sh $(START) $(END)

# ---- Test ----

test-profiles: ## Validate all training profiles
	./tests/test-profile.sh

test-lint: ## Run lint checks (shell, YAML, secrets, Dockerfiles)
	./tests/lint.sh

test-base-image: build-base ## Build and test the base image
	./tests/test-base-image.sh $(IMAGE_NAME):$(IMAGE_TAG)

test: test-lint test-profiles ## Run all local tests (lint + profiles)

# ---- Profiles ----

list-profiles: ## List available training profiles
	@./admin/admin-workflow.sh profiles

# ---- Operations ----

status: ## Quick cluster status
	@./admin/admin-workflow.sh status

monitor: ## Monitor student environments
	@./admin/admin-workflow.sh manage monitor

clean: ## Teardown student environments (interactive)
	./admin/admin-workflow.sh manage teardown

# ---- Legacy ----

build: build-monolith ## Alias: build monolith image

deploy: deploy-legacy ## Alias: legacy deploy
