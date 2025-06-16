# Makefile for Code Server Student Image

# Variables
IMAGE_NAME ?= code-server-student
IMAGE_TAG ?= latest
REGISTRY ?= image-registry.openshift-image-registry.svc:5000/devops
FULL_IMAGE_NAME = $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
CLUSTER_DOMAIN ?= apps.cluster.local

# Default number of students for testing
STUDENT_COUNT ?= 3

.PHONY: help build deploy clean monitor test

help: ## Show this help message
	@echo "Code Server Student Image - Makefile"
	@echo
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build the code-server image using Shipwright
	@echo "Building code-server student image..."
	oc apply -f shipwright/build.yaml
	oc create -f shipwright/buildrun.yaml
	@echo "Build initiated. Monitor with: oc logs -f buildrun/code-server-student-image-xxxxx -n devops"

deploy: ## Deploy student environments (use STUDENT_COUNT=N to specify number)
	@echo "Deploying $(STUDENT_COUNT) student environments..."
	chmod +x deploy-students.sh
	./deploy-students.sh -n $(STUDENT_COUNT) -d $(CLUSTER_DOMAIN)

deploy-specific: ## Deploy specific students (use STUDENTS="name1,name2,name3")
	@echo "Deploying specific students: $(STUDENTS)"
	chmod +x deploy-students.sh
	./deploy-students.sh -s $(STUDENTS) -d $(CLUSTER_DOMAIN)

monitor: ## Monitor student environment status
	@echo "Monitoring student environments..."
	chmod +x monitor-students.sh
	./monitor-students.sh

clean: ## Clean up all student environments
	@echo "Cleaning up student environments..."
	chmod +x deploy-students.sh
	./deploy-students.sh -n $(STUDENT_COUNT) --cleanup

clean-all: ## Clean up ALL student environments (be careful!)
	@echo "WARNING: This will delete ALL student namespaces!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	oc get namespaces -l student --no-headers -o custom-columns=":metadata.name" | xargs -I {} oc delete namespace {}

test: ## Test deployment with a small number of students
	@echo "Testing with 2 student environments..."
	$(MAKE) STUDENT_COUNT=2 deploy
	sleep 30
	$(MAKE) monitor
	@echo "Test complete. Clean up with: make STUDENT_COUNT=2 clean"

logs: ## Show recent logs from student environments
	@echo "Recent logs from student pods..."
	@for ns in $$(oc get namespaces -l student --no-headers -o custom-columns=":metadata.name" | head -5); do \
		echo "=== Logs for $$ns ==="; \
		oc logs -n $$ns deployment/code-server --tail=10 2>/dev/null || echo "No logs available"; \
		echo; \
	done

status: ## Quick status check
	@echo "Quick status check..."
	@echo "Student namespaces: $$(oc get namespaces -l student --no-headers | wc -l)"
	@echo "Running pods: $$(oc get pods -A -l app=code-server --no-headers | grep Running | wc -l)"
	@echo "Failed pods: $$(oc get pods -A -l app=code-server --no-headers | grep -v Running | grep -v Completed | wc -l)"

backup: ## Create backup of student credentials
	@echo "Creating backup of student credentials..."
	@if [ -f student-credentials.txt ]; then \
		cp student-credentials.txt student-credentials-backup-$$(date +%Y%m%d-%H%M%S).txt; \
		echo "Backup created: student-credentials-backup-$$(date +%Y%m%d-%H%M%S).txt"; \
	else \
		echo "No credentials file found"; \
	fi

# Development targets
dev-build: ## Build image locally with Docker/Podman
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

dev-test: ## Test the image locally
	docker run -it --rm -p 8080:8080 $(IMAGE_NAME):$(IMAGE_TAG)

# Template management
template-install: ## Install the student template in OpenShift
	oc apply -f student-template.yaml

template-remove: ## Remove the student template from OpenShift
	oc delete template code-server-student -n devops --ignore-not-found=true

# Examples
example-deploy-class: ## Example: Deploy a class of 20 students
	$(MAKE) STUDENT_COUNT=20 CLUSTER_DOMAIN=apps.ocp4.example.com deploy

example-deploy-workshop: ## Example: Deploy workshop participants
	$(MAKE) STUDENTS="alice,bob,charlie,diana,eve" deploy-specific
