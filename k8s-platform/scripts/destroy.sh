#!/bin/sh

INSTALL_PATH="/usr/local/bin"

echo "Starting cleanup of Minikube and K8s platform tools..."

if command -v minikube >/dev/null 2>&1; then
    echo "Stopping and deleting Minikube cluster..."
    minikube stop
    minikube delete --all --purge
else
    echo "Minikube is not installed, skipping cluster deletion."
fi

echo "Removing hidden configuration and cache directories..."
rm -rf "$HOME/.minikube"
rm -rf "$HOME/.kube"
rm -rf "$HOME/.helm"
rm -rf "$HOME/.config/k9s"

echo "Removing binary tools from $INSTALL_PATH..."
TOOLS="minikube kubectl helm kubectx kubens k9s"

for tool in $TOOLS; do
    if [ -f "$INSTALL_PATH/$tool" ]; then
        echo "Deleting $tool..."
        sudo rm -f "$INSTALL_PATH/$tool"
    fi
done