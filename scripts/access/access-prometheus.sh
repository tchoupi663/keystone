#!/bin/bash
set -e

NAMESPACE="observability"

echo "Starting port-forward to Prometheus..."
echo "Visit: http://localhost:9090"
echo ""

kubectl port-forward -n ${NAMESPACE} svc/prometheus-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 & PORT_FORWARD_PID=$!

if command -v open &> /dev/null; then
    sleep 2
    open http://localhost:9090
fi

wait $PORT_FORWARD_PID