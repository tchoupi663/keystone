
# Keystone Makefile
#
# Helper commands for managing the Keystone infrastructure and development environment.

.PHONY: help install start-local check access-grafana access-prometheus creds clean

# Default target
help:
	@echo "Keystone Project Makefile"
	@echo "-------------------------"
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  install            Install prerequisites (tools required for this project)"
	@echo "  start-local        Start the local Minikube environment"
	@echo "  check              Run health checks on the environment"
	@echo "  creds              Retrieve necessary credentials"
	@echo "  access-grafana     Port-forward and access Grafana dashboard"
	@echo "  access-prometheus  Port-forward and access Prometheus dashboard"
	@echo "  clean              Destroy the local environment"
	@echo ""

# Install necessary tools
install:
	@echo "Installing prerequisites..."
	@bash scripts/install-prerequisites.sh

# Start local Minikube cluster
start-local:
	@echo "Starting local Minikube cluster..."
	@bash scripts/local/setup-minikube-local.sh

# Run health checks
check:
	@echo "Running health checks..."
	@bash scripts/health-check.sh

# Get credentials
creds:
	@echo "Retrieving credentials..."
	@bash scripts/get_credentials.sh

# Access Grafana
access-grafana:
	@echo "Setting up access to Grafana..."
	@bash scripts/access/access-grafana.sh

# Access Prometheus
access-prometheus:
	@echo "Setting up access to Prometheus..."
	@bash scripts/access/access-prometheus.sh

# Clean up / Destroy environment
clean:
	@echo "Destroying environment..."
	@bash scripts/destroy.sh
