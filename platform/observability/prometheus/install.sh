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

echo "Installing prometheus stack (prometheus, grafana, promtail)..." >&2

helm uninstall -n ${NAMESPACE} prometheus
helm uninstall -n ${NAMESPACE} promtail

sleep 30

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update 

helm upgrade --install prometheus \
    prometheus-community/kube-prometheus-stack \
    --namespace ${NAMESPACE} \
    --create-namespace \
    ${VALUES_FILES[@]} \
    --wait

helm upgrade --install promtail grafana/promtail \
  --namespace ${NAMESPACE} \
  --set "config.clients[0].url=http://loki-gateway.${NAMESPACE}.svc.cluster.local/loki/api/v1/push" \
  --values ${SCRIPT_DIR}/promtail-values-${ENVIRONMENT}.yaml

echo "Successfully installed prometheus stack (prometheus, grafana, promtail)" >&2

GRAFANA_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

SECRETS_DIR=${SCRIPT_DIR}/../../../.secrets
mkdir -p ${SECRETS_DIR}
echo "Grafana access: " 
echo "Username: admin " > ${SECRETS_DIR}/grafana_username.txt
echo "Password: ${GRAFANA_PASSWORD}" > ${SECRETS_DIR}/grafana_password.txt

echo "Grafana access: " 
echo "Username: admin" 
echo "Password: ${GRAFANA_PASSWORD}" 
echo "Run kubectl port-forward -n ${NAMESPACE} svc/prometheus-grafana 3000:80"
echo "then http://localhost:3000" 

echo "Prometheus access: " 
echo "Run kubectl port-forward -n ${NAMESPACE} svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "then http://localhost:9090" 

echo "AlertManager access: " 
echo "Run kubectl port-forward -n ${NAMESPACE} svc/prometheus-kube-prometheus-prometheus 9093:9093"
echo "then http://localhost:9093" 

echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l "release=prometheus" \
  -n ${NAMESPACE} \
  --timeout=300s
echo "Ready"