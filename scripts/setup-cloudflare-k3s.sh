#!/bin/bash

# Cloudflare Tunnel Setup Script for K3s
# This script helps you set up Cloudflare Tunnel on your Raspberry Pi with K3s

set -e

echo "================================================"
echo "Cloudflare Tunnel Setup - Kubernetes (K3s)"
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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if k3s is running
if ! systemctl is-active --quiet k3s; then
    echo "❌ K3s is not running. Please start K3s first."
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
K3S_DIR="$SCRIPT_DIR/../k3s"

echo ""
echo "Creating Kubernetes secret..."

# Check if secret already exists
if kubectl get secret cloudflare-tunnel -n kube-system &>/dev/null; then
    echo "⚠️  Secret 'cloudflare-tunnel' already exists"
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete secret cloudflare-tunnel -n kube-system
        echo "✅ Deleted existing secret"
    else
        echo "Using existing secret"
    fi
fi

# Create secret if it doesn't exist
if ! kubectl get secret cloudflare-tunnel -n kube-system &>/dev/null; then
    kubectl create secret generic cloudflare-tunnel \
        --from-literal=token="$CF_TUNNEL_TOKEN" \
        -n kube-system
    echo "✅ Created cloudflare-tunnel secret"
fi

echo ""
echo "Deploying Cloudflare Tunnel to K3s..."

# Apply manifests
kubectl apply -f "$K3S_DIR/manifests/cloudflare/"

echo ""
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s \
    deployment/cloudflared -n kube-system

echo ""
echo "✅ Cloudflare Tunnel deployed successfully!"
echo ""
echo "Deployment status:"
kubectl get pods -n kube-system -l app=cloudflared

echo ""
echo "Next steps:"
echo "==========="
echo "1. Check tunnel status:"
echo "   kubectl logs -n kube-system -l app=cloudflared --tail=50"
echo ""
echo "2. Verify in Cloudflare dashboard:"
echo "   https://one.dash.cloudflare.com → Access → Tunnels"
echo "   Your tunnel should show as HEALTHY"
echo ""
echo "3. Configure public hostnames in Cloudflare:"
echo "   - Add your subdomain (e.g., node.yourdomain.com)"
echo "   - Point it to: http://traefik.kube-system:80"
echo "   - Repeat for each service you want to expose"
echo ""
echo "4. Test your services:"
echo "   curl https://yourdomain.com"
echo ""
echo "See docs/CLOUDFLARE-TUNNEL.md for detailed configuration"
echo ""
