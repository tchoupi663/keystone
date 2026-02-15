#!/bin/sh

CMD=${1:-install}

install() {
    echo "Checking device..." >&2

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case ${OS} in
        darwin*) OS=darwin ;;
        linux*) OS=linux ;;
        *) echo "Unsupported OS: ${OS}" >&2; exit 1 ;;
    esac

    ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
    case ${ARCH} in
        x86_64|amd64*) ARCH=amd64 ;;
        arm64|aarch64x*) ARCH=arm64 ;;
        ppc64le) ARCH="ppc64le" ;;
        s390x) ARCH="s390x" ;;
        *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
    esac

    echo "Detected: ${OS} (${ARCH})" >&2

    MINIKUBE_URL="https://github.com/kubernetes/minikube/releases/latest/download/minikube-${OS}-${ARCH}"
    echo "Downloading from: ${MINIKUBE_URL}" >&2
    curl -LO ${MINIKUBE_URL}

    case $OS in
        linux*) 
            sudo install -m 755 minikube-${OS}-${ARCH} /usr/local/bin/minikube && rm minikube-linux-amd64
            echo "Starting local cluster..." >&2
            minikube start --driver=none
        ;;
        darwin*)
            sudo install -m 755 minikube-${OS}-${ARCH} /usr/local/bin/minikube

            echo "Ensuring Docker (preferred option) is installed and running..."
            if ! command -v docker >/dev/null 2>&1; then
                echo "Error: Docker is not installed." >&2
                exit 1
            fi

            if ! docker info >/dev/null 2>&1; then
                echo "Error: Docker not running. Open Docker Desktop application" >&2
                exit 1
            fi

            DOCKER_VER=$(docker version --format '{{.Server.Version}}')
            echo "Successfully connected to Docker Engine v${DOCKER_VER}"

            rm minikube-${OS}-${ARCH}
            minikube start
        ;;
        *)
            echo "Installation script not found" >&2
        ;;
    esac

    echo "Setup complete!" >&2

    echo "Enabling ingress..." >&2
    minikube addons enable ingress

    sleep 10

    minikube status

}

remove() {
    echo "Starting removal process..." >&2

    if command -v minikube >/dev/null 2>&1; then
        echo "Deleting minikube cluster and local state..." >&2
        minikube stop >/dev/null 2>&1
        minikube delete --all --purge
    fi

    if [ -f "/usr/local/bin/minikube" ]; then
        echo "Removing minikube binary from /usr/local/bin..."
        sudo rm -f /usr/local/bin/minikube
    fi

    echo "Cleaning up configuration directories (~/.minikube, ~/.kube)..." >&2
    rm -rf "${HOME}/.minikube" 
    rm -rf "${HOME}/.kube"

    echo "Minikube has been successfully removed." >&2
}


case ${CMD} in 
    install)
        install
        ;;
    remove)
        remove
        ;;
    *)
        echo "Usage: setup.sh [install|remove]" >&2
    ;;
esac
