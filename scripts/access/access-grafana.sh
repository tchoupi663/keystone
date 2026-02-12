#!/bin/bash
set -e

NAMESPACE="observability"

echo "Getting Grafana credentials..."
PASSWORD=$(kubectl get secret -n ${NAMESPACE} prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo ""
echo "Grafana credentials:"
echo "  Username: admin"
echo "  Password: ${PASSWORD}"
echo ""
echo "Starting port-forward to Grafana..."
echo "Visit: http://localhost:3000"
echo "Keep this terminal open to keep the connection alive."
echo "Ctrl+C to stop."

kubectl port-forward -n ${NAMESPACE} svc/prometheus-grafana 3000:80 >/dev/null 2>&1 & PORT_FORWARD_PID=$!

if command -v open &> /dev/null; then
    sleep 2
    open http://localhost:3000
fi

wait $PORT_FORWARD_PID