#!/bin/bash

# K3s Troubleshooting Script
# Run this to diagnose K3s installation issues

echo "================================"
echo "K3s Troubleshooting"
echo "================================"
echo ""

echo "1. Checking system requirements..."
echo ""

# Check architecture
echo "Architecture: $(uname -m)"

# Check memory
echo "Memory:"
free -h | grep "Mem:"

# Check cgroups
echo ""
echo "2. Checking cgroups configuration..."
if [ -f /boot/firmware/cmdline.txt ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/cmdline.txt ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    echo "❌ Could not find cmdline.txt"
    CMDLINE_FILE=""
fi

if [ -n "$CMDLINE_FILE" ]; then
    echo "Cmdline file: $CMDLINE_FILE"
    cat $CMDLINE_FILE
    echo ""
    
    if grep -q "cgroup_memory=1" $CMDLINE_FILE; then
        echo "✅ Memory cgroups enabled"
    else
        echo "❌ Memory cgroups NOT enabled"
        echo "   Add to $CMDLINE_FILE:"
        echo "   cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"
    fi
fi

echo ""
echo "3. Checking K3s service status..."
sudo systemctl status k3s.service --no-pager || true

echo ""
echo "4. Checking K3s logs (last 50 lines)..."
sudo journalctl -xeu k3s.service --no-pager -n 50 || true

echo ""
echo "5. Checking if port 6443 is available..."
sudo netstat -tulpn | grep 6443 || echo "Port 6443 is free"

echo ""
echo "6. Checking available disk space..."
df -h /

echo ""
echo "7. Checking iptables..."
sudo iptables -L -n | head -20

echo ""
echo "================================"
echo "Common Fixes:"
echo "================================"
echo ""
echo "If cgroups not enabled:"
echo "  sudo nano $CMDLINE_FILE"
echo "  Add: cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"
echo "  sudo reboot"
echo ""
echo "If port conflict:"
echo "  sudo lsof -i :6443"
echo "  Kill conflicting process or change K3s port"
echo ""
echo "If permission issues:"
echo "  sudo chown -R root:root /var/lib/rancher"
echo "  sudo chmod -R 755 /var/lib/rancher"
echo ""
echo "To completely remove K3s and start fresh:"
echo "  /usr/local/bin/k3s-uninstall.sh"
echo "  sudo rm -rf /var/lib/rancher"
echo "  sudo rm -rf /etc/rancher"
echo ""
