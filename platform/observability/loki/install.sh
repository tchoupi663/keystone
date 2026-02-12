#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="observability"
ENVIRONMENT="${1:-local}" 

if [[ ! "$ENVIRONMENT" =~ ^(local|aws|gcp|azure)$ ]]; then
    echo "Environment doesn't exist"
    echo "Usage: $0 [local|aws|gcp|azure]"
    exit 1
fi

VALUES_FILES=(
  "--values ${SCRIPT_DIR}/values-base.yaml"
  "--values ${SCRIPT_DIR}/values-${ENVIRONMENT}.yaml"
)

helm uninstall -n ${NAMESPACE} loki

sleep 30

echo "Installing loki and promtail (necessary for loki)..." >&2

helm repo add grafana https://grafana.github.io/helm-charts

helm repo update

helm upgrade --install loki grafana/loki \
    --namespace ${NAMESPACE} \
    --create-namespace \
    ${VALUES_FILES[@]}
