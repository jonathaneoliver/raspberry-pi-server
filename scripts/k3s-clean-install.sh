#!/bin/bash

# K3s Complete Cleanup and Reinstall Script

set -e

echo "================================"
echo "K3s Clean Reinstall"
echo "================================"
echo ""

echo "1️⃣  Stopping K3s service..."
sudo systemctl stop k3s || true
sudo systemctl stop k3s-agent || true

echo ""
echo "2️⃣  Uninstalling K3s..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
else
    echo "K3s not installed or already uninstalled"
fi

echo ""
echo "3️⃣  Removing all K3s data and configuration..."
sudo rm -rf /var/lib/rancher
sudo rm -rf /etc/rancher
sudo rm -rf /var/lib/kubelet
sudo rm -rf /run/k3s
sudo rm -rf ~/.kube

echo ""
echo "4️⃣  Cleaning up remaining processes..."
sudo pkill -9 -f k3s || true
sudo pkill -9 -f containerd || true

echo ""
echo "5️⃣  Removing systemd service files..."
sudo rm -f /etc/systemd/system/k3s.service
sudo rm -f /etc/systemd/system/k3s-agent.service
sudo systemctl daemon-reload

echo ""
echo "6️⃣  Cleaning up network interfaces..."
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete cni0 2>/dev/null || true

echo ""
echo "✅ K3s completely removed!"
echo ""
echo "7️⃣  Installing fresh K3s (without PodSecurityPolicy)..."
echo ""

# Install K3s with simple, modern configuration
curl -sfL https://get.k3s.io | sh -s - server \
    --disable servicelb \
    --write-kubeconfig-mode 644 \
    --node-label node.kubernetes.io/type=edge

echo ""
echo "⏳ Waiting for K3s to start..."
sleep 15

echo ""
echo "8️⃣  Setting up kubectl access..."
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# Add to bashrc if not already there
if ! grep -q "KUBECONFIG" $HOME/.bashrc; then
    echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
fi

echo ""
echo "9️⃣  Verifying installation..."
kubectl get nodes

echo ""
echo "================================"
echo "✅ K3s Installation Complete!"
echo "================================"
echo ""
echo "K3s Version: $(sudo k3s --version | head -n1)"
echo ""
echo "Check cluster status:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "Next step:"
echo "  cd raspberry-pi-server/k3s"
echo "  ./deploy.sh"
echo ""
