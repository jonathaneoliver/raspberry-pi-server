#!/bin/bash

# Simple K3s Installation Script
# Just installs K3s with correct settings

set -e

echo "================================"
echo "Installing K3s"
echo "================================"
echo ""

echo "📥 Downloading and installing K3s..."
curl -sfL https://get.k3s.io | sh -s - server \
    --disable servicelb \
    --write-kubeconfig-mode 644

echo ""
echo "⏳ Waiting for K3s to start (30 seconds)..."
sleep 30

echo ""
echo "✅ Checking K3s status..."
sudo systemctl status k3s --no-pager || true

echo ""
echo "📝 Setting up kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config 2>/dev/null || true
sudo chown $(id -u):$(id -g) $HOME/.kube/config 2>/dev/null || true
export KUBECONFIG=$HOME/.kube/config

# Add to bashrc
if ! grep -q "KUBECONFIG" $HOME/.bashrc; then
    echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
fi

echo ""
echo "🔍 Testing kubectl..."
export KUBECONFIG=$HOME/.kube/config
/usr/local/bin/kubectl get nodes

echo ""
echo "================================"
echo "✅ Installation Complete!"
echo "================================"
echo ""
echo "Run these commands to set up kubectl in your current shell:"
echo "  export KUBECONFIG=\$HOME/.kube/config"
echo "  kubectl get nodes"
echo ""
echo "Or log out and back in for permanent effect."
echo ""
