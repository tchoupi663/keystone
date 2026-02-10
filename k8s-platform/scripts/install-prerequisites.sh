#!/bin/sh

CMD=${1:-install}
INSTALL_PATH="/usr/local/bin"

get_env() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $OS in
        darwin*) OS=darwin ;;
        linux*) OS=linux ;;
        *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
    esac

    ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
    case $ARCH in
        x86_64|amd64*) ARCH=amd64 ;;
        arm64|aarch64*) ARCH=arm64 ;;
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac
}

install_tools() {
    get_env
    echo "Detected: $OS ($ARCH). Installing ecosystem tools..." >&2

    if ! command -v helm >/dev/null 2>&1; then
        echo "Installing Helm..." >&2
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    if ! command -v kubectl >/dev/null 2>&1; then
        echo "Installing kubectl..." >&2
        K8S_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/$K8S_VER/bin/$OS/$ARCH/kubectl"
        chmod +x kubectl
        sudo mv kubectl "$INSTALL_PATH/"
    fi

    for tool in kubectx kubens; do
        if ! command -v $tool >/dev/null 2>&1; then
            echo "Installing $tool..."
            curl -LO "https://raw.githubusercontent.com/ahmetb/kubectx/master/$tool"
            chmod +x "$tool"
            sudo mv "$tool" "$INSTALL_PATH/"
        fi
    done

    if ! command -v k9s >/dev/null 2>&1; then
        echo "Installing k9s..."
        OS_CAP=$(echo "$OS" | awk '{print toupper(substr($0,1,1))substr($0,2)}')
        K9S_URL="https://github.com/derailed/k9s/releases/latest/download/k9s_${OS_CAP}_${ARCH}.tar.gz"
        curl -LO "$K9S_URL"
        tar -xzf k9s_${OS_CAP}_${ARCH}.tar.gz k9s
        chmod +x k9s
        sudo mv k9s "$INSTALL_PATH/"
        rm k9s_${OS_CAP}_${ARCH}.tar.gz
    fi

    echo "Helm:    $(helm version --short 2>/dev/null)"
    echo "Kubectl: $(kubectl version --client --short 2>/dev/null)"
    echo "k9s:     $(k9s version | grep 'Version' | awk '{print $2}' 2>/dev/null)"
    echo "kubectx: Ready"
    echo "kubens:  Ready"
}

remove_tools() {
    echo "Removing tools from $INSTALL_PATH..." >&2
    sudo rm -f "$INSTALL_PATH/helm" "$INSTALL_PATH/kubectx" \
               "$INSTALL_PATH/kubens" "$INSTALL_PATH/kubectl" \
               "$INSTALL_PATH/k9s"
    echo "Cleanup complete." >&2
}

case $CMD in 
    install) install_tools ;;
    remove)  remove_tools ;;
    *) echo "Usage: $0 [install|remove]" ;;
esac