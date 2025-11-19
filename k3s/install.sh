#!/bin/bash

# K3s Installation Script for Raspberry Pi 5
# Installs K3s with Traefik ingress controller

set -e

echo "================================"
echo "K3s Installation Script"
echo "================================"
echo ""

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo "⚠️  Warning: Not running on ARM64 architecture (detected: $ARCH)"
    echo "This script is optimized for Raspberry Pi 5"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for memory cgroups
echo "🔍 Checking system requirements..."
if ! grep -q "cgroup_memory=1" /boot/firmware/cmdline.txt 2>/dev/null && ! grep -q "cgroup_memory=1" /boot/cmdline.txt 2>/dev/null; then
    echo "⚠️  Memory cgroups not enabled!"
    echo ""
    echo "To enable, add to /boot/firmware/cmdline.txt (or /boot/cmdline.txt):"
    echo "  cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"
    echo ""
    read -p "Continue installation anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please enable cgroups and reboot, then run this script again."
        exit 1
    fi
fi

# Check if K3s is already installed
if command -v k3s &> /dev/null; then
    echo "⚠️  K3s is already installed!"
    read -p "Reinstall? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Uninstalling existing K3s..."
        /usr/local/bin/k3s-uninstall.sh || true
        sleep 3
    else
        echo "✅ Using existing K3s installation"
        exit 0
    fi
fi

echo ""
echo "📥 Installing K3s..."
echo ""

# Install K3s with Traefik enabled
curl -sfL https://get.k3s.io | sh -s - server \
    --disable servicelb \
    --write-kubeconfig-mode 644 \
    --node-label node.kubernetes.io/type=edge

echo ""
echo "⏳ Waiting for K3s to be ready..."
sleep 10

# Wait for node to be ready
kubectl wait --for=condition=Ready node --all --timeout=300s

echo ""
echo "✅ K3s installed successfully!"
echo ""

# Set up kubectl for current user
if [ "$EUID" -ne 0 ]; then
    echo "📝 Setting up kubectl access..."
    mkdir -p $HOME/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=$HOME/.kube/config
    echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
fi

echo ""
echo "🔍 Checking cluster status..."
kubectl get nodes
echo ""
kubectl get pods -A

echo ""
echo "================================"
echo "K3s Installation Complete!"
echo "================================"
echo ""
echo "Cluster Information:"
echo "  Node: $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
echo "  K3s Version: $(k3s --version | head -n1)"
echo "  Kubernetes: $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"
echo ""
echo "Useful Commands:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  kubectl get services -A"
echo "  sudo systemctl status k3s"
echo ""
echo "Next Steps:"
echo "  1. Deploy applications: ./deploy.sh"
echo "  2. Install Rancher (optional): kubectl apply -f manifests/rancher/"
echo "  3. Install ArgoCD (optional): kubectl apply -f manifests/argocd/"
echo ""
echo "To uninstall K3s:"
echo "  /usr/local/bin/k3s-uninstall.sh"
echo ""
