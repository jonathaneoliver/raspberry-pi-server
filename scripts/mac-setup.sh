#!/bin/bash

# Mac Setup Script for Raspberry Pi K3s Cluster Management
# Sets up kubectl access and installs GUI tools

set -e

echo "================================"
echo "K3s Management Setup for Mac"
echo "================================"
echo ""

# Check if we can reach the Pi
PI_HOST="${1:-raspberrypi.local}"
echo "🔍 Checking connection to $PI_HOST..."
if ! ping -c 1 $PI_HOST &> /dev/null; then
    echo "❌ Cannot reach $PI_HOST"
    echo "Usage: $0 [pi-hostname-or-ip]"
    exit 1
fi
echo "✅ Pi is reachable"

echo ""
echo "📥 Copying kubeconfig from Pi..."
mkdir -p ~/.kube

# Backup existing config if present
if [ -f ~/.kube/config ]; then
    echo "⚠️  Backing up existing kubeconfig..."
    cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d_%H%M%S)
fi

# Copy config from Pi
scp pi@$PI_HOST:~/.kube/config ~/.kube/config

# Update server address to use hostname/IP
echo "🔧 Updating kubeconfig server address..."
if [[ "$PI_HOST" != "raspberrypi.local" ]]; then
    sed -i '' "s/https:\/\/127.0.0.1:6443/https:\/\/$PI_HOST:6443/" ~/.kube/config
fi

echo ""
echo "✅ Testing kubectl connection..."
kubectl get nodes

echo ""
echo "🎨 Installing GUI tools..."

# Install k9s
if ! command -v k9s &> /dev/null; then
    echo "Installing k9s..."
    brew install derailed/k9s/k9s
else
    echo "✅ k9s already installed"
fi

# Install Lens
if ! command -v lens &> /dev/null; then
    echo "Installing Lens..."
    brew install --cask lens
else
    echo "✅ Lens already installed"
fi

echo ""
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "Available commands:"
echo ""
echo "Terminal UI (immediate):"
echo "  k9s"
echo ""
echo "Desktop App (best experience):"
echo "  open -a Lens"
echo ""
echo "Command line:"
echo "  kubectl get pods -A"
echo "  kubectl get nodes"
echo "  kubectl logs -f <pod-name> -n apps"
echo ""
echo "Port forwarding (access apps from Mac):"
echo "  kubectl port-forward -n apps svc/node-app 3000:3000"
echo "  kubectl port-forward -n apps svc/python-app 8000:8000"
echo ""
echo "Quick status check:"
echo "  kubectl get pods -n apps"
echo "  kubectl get pods -n databases"
echo ""
