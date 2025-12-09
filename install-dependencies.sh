#!/bin/bash

# Script to install security scanning tools and dependencies

set -e

SEPARATOR="================================================================================"
SUB_SEPARATOR="--------------------------------------------------------------------------------"

echo ""
echo "$SEPARATOR"
echo "                       Security Tools Installation Script"
echo "$SEPARATOR"
echo ""

# Install basic dependencies
echo "$SUB_SEPARATOR"
echo ">>> Checking Basic Dependencies"
echo "$SUB_SEPARATOR"
if ! dpkg -s wget gnupg jq zip >/dev/null 2>&1; then
    # Update system packages
    echo "Updating system packages..."
    sudo apt-get update
    echo "Installing missing dependencies..."
    sudo apt-get install -y wget gnupg jq zip
else
    echo "Basic dependencies already installed."
fi
echo ""

# Install Trivy
echo "$SUB_SEPARATOR"
echo ">>> Installing Trivy"
echo "$SUB_SEPARATOR"
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.68.1
echo ""

# Install kube-bench
echo "$SUB_SEPARATOR"
echo ">>> Installing kube-bench"
echo "$SUB_SEPARATOR"
KUBE_BENCH_DIR="/opt/kube-bench"
sudo mkdir -p "$KUBE_BENCH_DIR"
wget -q --show-progress https://github.com/aquasecurity/kube-bench/releases/download/v0.14.0/kube-bench_0.14.0_linux_amd64.tar.gz -O /tmp/kube-bench.tar.gz
sudo tar -xzf /tmp/kube-bench.tar.gz -C "$KUBE_BENCH_DIR"
sudo chmod +x "$KUBE_BENCH_DIR/kube-bench"
rm /tmp/kube-bench.tar.gz
echo "kube-bench installed at: $KUBE_BENCH_DIR"
echo ""

# Install kyverno CLI
echo "$SUB_SEPARATOR"
echo ">>> Installing Kyverno CLI"
echo "$SUB_SEPARATOR"
wget -q --show-progress https://github.com/kyverno/kyverno/releases/download/v1.16.0/kyverno-cli_v1.16.0_linux_x86_64.tar.gz -O /tmp/kyverno.tar.gz
tar -xzf /tmp/kyverno.tar.gz -C /tmp/
sudo mv /tmp/kyverno /usr/local/bin/
rm /tmp/kyverno.tar.gz
echo ""


echo "$SEPARATOR"
echo "                  Setting up Kalilinux Pod for Nmap Scanning"
echo "$SEPARATOR"
echo ""

# Create kalilinux pod if it doesn't exist
if ! kubectl get pod -n default kalilinux >/dev/null 2>&1; then
    echo "Creating kalilinux pod..."
    kubectl run kalilinux -n default --image=quay.io/abhilash_bs1/kalilinux:latest --restart=Never --command -- sleep infinity
else
    echo "kalilinux pod already exists."
fi

# Wait for pod to be ready
echo "Waiting for kalilinux pod to be ready..."
kubectl wait --for=condition=Ready pod/kalilinux -n default --timeout=300s
echo ""

echo "$SEPARATOR"
echo "                           Installation Complete"
echo "$SEPARATOR"
echo ""
echo "Installed Tools Summary:"
echo "$SUB_SEPARATOR"
echo "Trivy      : $(trivy --version | head -n 1)"
echo "kube-bench : $("$KUBE_BENCH_DIR/kube-bench" version)"
echo "Kyverno    : $(kyverno version | head -n 1)"
echo "$SEPARATOR"
echo ""

