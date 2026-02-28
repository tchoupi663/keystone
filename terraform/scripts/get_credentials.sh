#!/bin/bash

set -e

NAMESPACE="${1:-observability}"

echo "PLATFORM CREDENTIALS:"

#grafana
if kubectl get secret prometheus-grafana -n ${NAMESPACE} &> /dev/null; then
    echo "Grafana access:"
    echo "Username: admin"
    echo "Password: $(kubectl get secret -n ${NAMESPACE} prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
    echo "  URL: http://localhost:3000"
    echo "  Port-forward: kubectl port-forward -n ${NAMESPACE} svc/prometheus-grafana 3000:80"
    echo ""
fi