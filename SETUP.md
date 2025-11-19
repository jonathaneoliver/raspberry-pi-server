# Initial Raspberry Pi 5 Setup Guide

Complete guide to prepare your Raspberry Pi 5 for self-hosting.

## Hardware Requirements

- **Raspberry Pi 5** (4GB or 8GB RAM recommended)
- **Power Supply**: Official 27W USB-C power supply
- **Storage**: 32GB+ microSD card (Class 10/U3) OR NVMe SSD via PCIe HAT (recommended)
- **Cooling**: Active cooling recommended for sustained workloads
- **Network**: Ethernet recommended for stability

## Operating System Installation

### Option 1: Raspberry Pi OS Lite (Recommended)

1. **Download Raspberry Pi Imager**
   - https://www.raspberrypi.com/software/

2. **Flash OS to SD card/SSD**
   - Choose OS: Raspberry Pi OS Lite (64-bit)
   - Choose Storage: Your SD card/SSD
   - Settings (gear icon):
     - Enable SSH
     - Set username/password
     - Configure WiFi (if needed)
     - Set hostname: `raspberrypi` or custom

3. **Boot and Connect**
   ```bash
   # From your computer
   ssh pi@raspberrypi.local
   # Or use IP address if .local doesn't work
   ssh pi@192.168.1.XXX
   ```

### Option 2: Ubuntu Server 22.04 ARM64

1. Download from: https://ubuntu.com/download/raspberry-pi
2. Flash with Raspberry Pi Imager or balenaEtcher
3. Boot and SSH in (default user: ubuntu, password: ubuntu)

## Initial Configuration

### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### 2. Configure System Settings

```bash
# Run raspi-config (Raspberry Pi OS only)
sudo raspi-config
```

**Recommended settings:**
- System Options > Password > Change password
- System Options > Hostname > Set custom hostname
- Performance Options > Fan > Enable fan control
- Localization Options > Set timezone
- Advanced Options > Expand Filesystem

### 3. Install Essential Tools

```bash
sudo apt install -y \
  git \
  curl \
  wget \
  vim \
  htop \
  net-tools \
  ufw
```

### 4. Configure Firewall

```bash
# Enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow common service ports
sudo ufw allow 3000:9000/tcp

# Enable firewall
sudo ufw enable
```

### 5. Optimize for Server Use

#### Enable Memory Cgroups (Required for K3s)

```bash
# Edit cmdline.txt
sudo nano /boot/firmware/cmdline.txt
# Or on Raspberry Pi OS:
sudo nano /boot/cmdline.txt

# Add to the end of the line (no newlines):
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

#### Disable Unnecessary Services

```bash
# Disable WiFi if using Ethernet
sudo rfkill block wifi

# Disable Bluetooth
sudo systemctl disable bluetooth
sudo systemctl disable hciuart
```

#### Increase Swap (Optional, for 4GB RAM Pi)

```bash
# Edit dphys-swapfile
sudo nano /etc/dphys-swapfile

# Change CONF_SWAPSIZE
CONF_SWAPSIZE=2048

# Restart swap
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### 6. Set Static IP (Recommended)

#### For Raspberry Pi OS:

```bash
# Edit dhcpcd.conf
sudo nano /etc/dhcpcd.conf

# Add at the end:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8

# Restart networking
sudo systemctl restart dhcpcd
```

#### For Ubuntu Server:

```bash
# Edit netplan config
sudo nano /etc/netplan/50-cloud-init.yaml

# Example configuration:
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]

# Apply
sudo netplan apply
```

## Storage Optimization

### Using NVMe SSD (Highly Recommended)

If you have an NVMe HAT:

```bash
# Check if detected
lsblk

# You should see nvme0n1

# Format and mount
sudo mkfs.ext4 /dev/nvme0n1
sudo mkdir /mnt/nvme
sudo mount /dev/nvme0n1 /mnt/nvme

# Auto-mount on boot
echo '/dev/nvme0n1 /mnt/nvme ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab

# Move Docker data to NVMe (do this before installing Docker)
sudo mkdir -p /mnt/nvme/docker
```

## Install Docker

```bash
# Download and run installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable Docker on boot
sudo systemctl enable docker

# Log out and back in for group changes to take effect
exit
# SSH back in

# Test Docker
docker run hello-world
```

### Configure Docker to Use NVMe (if applicable)

```bash
# Create daemon.json
sudo nano /etc/docker/daemon.json

# Add:
{
  "data-root": "/mnt/nvme/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Restart Docker
sudo systemctl restart docker
```

## Install Docker Compose

```bash
# Install Docker Compose V2 (plugin)
sudo apt install -y docker-compose-plugin

# Verify
docker compose version
```

## System Monitoring

```bash
# Check temperature
vcgencmd measure_temp

# Check memory
free -h

# Check disk space
df -h

# System resources
htop
```

## Benchmark Your Pi

```bash
# CPU benchmark
sysbench cpu --cpu-max-prime=20000 run

# I/O benchmark (SD card)
sudo hdparm -t /dev/mmcblk0

# I/O benchmark (NVMe if available)
sudo hdparm -t /dev/nvme0n1
```

## Automated Setup Script

Run the complete setup automatically:

```bash
git clone <your-repo-url>
cd server
chmod +x scripts/pi-setup.sh
sudo ./scripts/pi-setup.sh
```

This script will:
- Update system
- Install Docker and Docker Compose
- Configure firewall
- Optimize system settings
- Set up monitoring tools

## Verify Setup

```bash
# Check Docker
docker --version
docker compose version
docker ps

# Check system
uname -a
free -h
df -h

# Check network
ip addr show
sudo ufw status
```

## Remote Access Setup (Optional)

### Tailscale (Recommended for secure remote access)

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate
sudo tailscale up

# Your Pi now has a Tailscale IP
tailscale ip -4
```

### Cloudflare Tunnel (Alternative)

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb

# Authenticate and create tunnel
cloudflared tunnel login
cloudflared tunnel create raspi
```

## Next Steps

1. Clone this repository
2. Choose Docker Compose or K3s
3. Follow deployment guide

See main [README.md](README.md) for deployment options.

## Troubleshooting

### SSH Connection Issues

```bash
# From your computer, check if Pi is reachable
ping raspberrypi.local

# Try IP address instead
nmap -sn 192.168.1.0/24  # Find Pi's IP
ssh pi@<ip-address>
```

### Docker Permission Issues

```bash
# Make sure you're in docker group
groups $USER

# If docker is not listed:
sudo usermod -aG docker $USER
# Log out and back in
```

### Out of Space

```bash
# Clean Docker
docker system prune -a

# Check what's using space
sudo du -sh /*
sudo du -sh /var/lib/docker/*
```

### Overheating

```bash
# Check temperature
vcgencmd measure_temp

# If >80°C, add cooling or reduce load
# Enable fan control in raspi-config
```

## Performance Tips

- Use Ethernet instead of WiFi
- Use SSD instead of SD card
- Enable active cooling
- Disable unnecessary services
- Use lightweight Docker images
- Monitor resource usage with htop/docker stats

## Security Checklist

- [ ] Changed default password
- [ ] Enabled UFW firewall
- [ ] SSH key authentication (disable password auth)
- [ ] Disabled root login
- [ ] Regular updates enabled
- [ ] Limited exposed ports
- [ ] Using non-root user for services

See [docs/SECURITY.md](docs/SECURITY.md) for detailed security guide.
