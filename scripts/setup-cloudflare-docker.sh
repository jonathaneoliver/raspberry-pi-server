#!/bin/bash

# Cloudflare Tunnel Setup Script for Docker Compose
# This script helps you set up Cloudflare Tunnel on your Raspberry Pi

set -e

echo "================================================"
echo "Cloudflare Tunnel Setup - Docker Compose"
echo "================================================"
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "Prerequisites Check:"
echo "==================="
echo ""
echo "Before continuing, make sure you have:"
echo "1. ✅ A domain name"
echo "2. ✅ Domain added to Cloudflare (free account)"
echo "3. ✅ Created a Cloudflare Tunnel"
echo "4. ✅ Copied your tunnel token"
echo ""
read -p "Have you completed all prerequisites? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please complete the prerequisites first:"
    echo "1. Sign up at https://dash.cloudflare.com"
    echo "2. Add your domain to Cloudflare"
    echo "3. Go to https://one.dash.cloudflare.com"
    echo "4. Navigate to Access → Tunnels"
    echo "5. Create a new tunnel and copy the token"
    echo ""
    echo "See docs/CLOUDFLARE-TUNNEL.md for detailed instructions"
    exit 1
fi

echo ""
echo "Enter your Cloudflare Tunnel token:"
echo "(It should start with 'ey...')"
read -r CF_TUNNEL_TOKEN

if [ -z "$CF_TUNNEL_TOKEN" ]; then
    echo "❌ Token cannot be empty"
    exit 1
fi

# Validate token format (basic check)
if [[ ! $CF_TUNNEL_TOKEN =~ ^ey ]]; then
    echo "⚠️  Warning: Token doesn't start with 'ey'. Are you sure this is correct?"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"

# Create or update .env file
ENV_FILE="$DOCKER_DIR/.env"

echo ""
echo "Updating $ENV_FILE..."

# Check if .env exists and backup
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backed up existing .env file"
fi

# Add or update CF_TUNNEL_TOKEN in .env
if grep -q "^CF_TUNNEL_TOKEN=" "$ENV_FILE" 2>/dev/null; then
    # Update existing token
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^CF_TUNNEL_TOKEN=.*|CF_TUNNEL_TOKEN=$CF_TUNNEL_TOKEN|" "$ENV_FILE"
    else
        sed -i "s|^CF_TUNNEL_TOKEN=.*|CF_TUNNEL_TOKEN=$CF_TUNNEL_TOKEN|" "$ENV_FILE"
    fi
    echo "✅ Updated CF_TUNNEL_TOKEN in .env"
else
    # Add new token
    echo "" >> "$ENV_FILE"
    echo "# Cloudflare Tunnel" >> "$ENV_FILE"
    echo "CF_TUNNEL_TOKEN=$CF_TUNNEL_TOKEN" >> "$ENV_FILE"
    echo "✅ Added CF_TUNNEL_TOKEN to .env"
fi

echo ""
echo "Starting Cloudflare Tunnel..."
cd "$DOCKER_DIR"

# Start cloudflared
docker-compose -f docker-compose.yml -f docker-compose.cloudflare.yml up -d cloudflared

echo ""
echo "✅ Cloudflare Tunnel deployed successfully!"
echo ""
echo "Next steps:"
echo "==========="
echo "1. Check tunnel status:"
echo "   docker logs -f cloudflared"
echo ""
echo "2. Verify in Cloudflare dashboard:"
echo "   https://one.dash.cloudflare.com → Access → Tunnels"
echo "   Your tunnel should show as HEALTHY"
echo ""
echo "3. Configure public hostnames in Cloudflare:"
echo "   - Add your subdomain (e.g., node.yourdomain.com)"
echo "   - Point it to: http://traefik:80"
echo "   - Repeat for each service you want to expose"
echo ""
echo "4. Test your services:"
echo "   curl https://yourdomain.com"
echo ""
echo "See docs/CLOUDFLARE-TUNNEL.md for detailed configuration"
echo ""
