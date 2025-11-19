#!/bin/bash

# Raspberry Pi Initial Setup Script
# Automates the initial configuration

set -e

echo "================================"
echo "Raspberry Pi Setup Script"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Please run without sudo. Script will ask for sudo when needed."
    exit 1
fi

echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "📦 Installing essential packages..."
sudo apt install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    ufw \
    ca-certificates \
    gnupg \
    lsb-release

echo ""
echo "🔥 Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 3000:9000/tcp comment 'Application ports'
sudo ufw --force enable

echo ""
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. You'll need to log out and back in for group changes."
else
    echo "✅ Docker already installed"
fi

echo ""
echo "🐙 Installing Docker Compose..."
if ! docker compose version &> /dev/null 2>&1; then
    sudo apt install -y docker-compose-plugin
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

echo ""
echo "⚙️  Optimizing Docker configuration..."
sudo mkdir -p /etc/docker

# Create Docker daemon.json if it doesn't exist
if [ ! -f /etc/docker/daemon.json ]; then
    cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    echo "✅ Docker configuration created"
else
    echo "⚠️  Docker configuration already exists, skipping"
fi

sudo systemctl enable docker
sudo systemctl restart docker

echo ""
echo "🔧 System optimizations..."

# Check if cgroups are enabled
if ! grep -q "cgroup_memory=1" /boot/firmware/cmdline.txt 2>/dev/null && \
   ! grep -q "cgroup_memory=1" /boot/cmdline.txt 2>/dev/null; then
    echo ""
    echo "⚠️  Memory cgroups not enabled!"
    echo "This is required for Kubernetes (K3s)"
    echo ""
    read -p "Enable memory cgroups? (required for K3s) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CMDLINE_FILE=""
        if [ -f /boot/firmware/cmdline.txt ]; then
            CMDLINE_FILE="/boot/firmware/cmdline.txt"
        elif [ -f /boot/cmdline.txt ]; then
            CMDLINE_FILE="/boot/cmdline.txt"
        fi
        
        if [ -n "$CMDLINE_FILE" ]; then
            sudo cp $CMDLINE_FILE ${CMDLINE_FILE}.backup
            sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' $CMDLINE_FILE
            echo "✅ Memory cgroups enabled. Reboot required!"
            REBOOT_REQUIRED=true
        else
            echo "❌ Could not find cmdline.txt"
        fi
    fi
fi

echo ""
echo "📊 Current system status:"
echo "  RAM: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo "  CPU Temp: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"

echo ""
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "Installed:"
echo "  - Docker $(docker --version 2>/dev/null | awk '{print $3}')"
echo "  - Docker Compose $(docker compose version 2>/dev/null | awk '{print $4}')"
echo ""

if [ "$REBOOT_REQUIRED" = true ]; then
    echo "⚠️  REBOOT REQUIRED for cgroup changes!"
    echo ""
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
else
    echo "Next steps:"
    echo "  1. Log out and back in (for Docker group changes)"
    echo "  2. Choose your deployment approach:"
    echo "     - Docker Compose: cd docker-compose && ./deploy.sh"
    echo "     - K3s: cd k3s && sudo ./install.sh"
fi

echo ""
echo "Happy self-hosting! 🚀"
