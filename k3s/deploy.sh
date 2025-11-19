#!/bin/bash

# K3s Deployment Script
# Deploys all applications to K3s cluster

set -e

echo "================================"
echo "K3s Application Deployment"
echo "================================"
echo ""

# Check if K3s is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found! Is K3s installed?"
    echo "Run: ./install.sh"
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster not accessible!"
    echo "Run: sudo systemctl start k3s"
    exit 1
fi

echo "🔍 Checking cluster status..."
kubectl get nodes
echo ""

# Build images locally (since we don't have a registry yet)
echo "🏗️  Building application images..."
echo ""

if [ -d "../apps/node-app" ]; then
    echo "Building Node.js app..."
    docker build -t node-app:latest ../apps/node-app
else
    echo "⚠️  Node.js app directory not found, skipping build"
fi

if [ -d "../apps/python-app" ]; then
    echo "Building Python app..."
    docker build -t python-app:latest ../apps/python-app
else
    echo "⚠️  Python app directory not found, skipping build"
fi

# Import images to K3s (for local development)
echo ""
echo "📦 Importing images to K3s..."
docker save node-app:latest | sudo k3s ctr images import - || echo "⚠️  Node.js image import failed"
docker save python-app:latest | sudo k3s ctr images import - || echo "⚠️  Python image import failed"

# Verify images
echo ""
echo "Verifying imported images..."
sudo k3s crictl images | grep -E "(node-app|python-app)" || echo "⚠️  Images not found, pods may fail to start"

echo ""
echo "📝 Deploying Kubernetes manifests..."
echo ""

# Create namespaces
echo "Creating namespaces..."
kubectl apply -f manifests/namespaces/

# Create ConfigMaps and Secrets
echo "Creating ConfigMaps and Secrets..."
kubectl apply -f manifests/configmaps/

# Deploy databases
echo "Deploying databases..."
kubectl apply -f manifests/deployments/apps.yaml

# Create services
echo "Creating services..."
kubectl apply -f manifests/services/

# Create ingress
echo "Creating ingress..."
kubectl apply -f manifests/ingress/

echo ""
echo "⏳ Waiting for deployments to be ready..."
echo ""

# Wait for databases to be ready
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n databases --timeout=300s || echo "⚠️  Timeout waiting for PostgreSQL"

echo "Waiting for Redis..."
kubectl wait --for=condition=ready pod -l app=redis -n databases --timeout=300s || echo "⚠️  Timeout waiting for Redis"

# Wait for applications
echo "Waiting for Node.js app..."
kubectl wait --for=condition=ready pod -l app=node-app -n apps --timeout=300s || echo "⚠️  Timeout waiting for Node.js app"

echo "Waiting for Python app..."
kubectl wait --for=condition=ready pod -l app=python-app -n apps --timeout=300s || echo "⚠️  Timeout waiting for Python app"

echo ""
echo "✅ Deployment complete!"
echo ""

echo "================================"
echo "Cluster Status:"
echo "================================"
kubectl get all -n databases
echo ""
kubectl get all -n apps
echo ""

echo "================================"
echo "Access Information:"
echo "================================"
echo ""
echo "Add these entries to /etc/hosts:"
echo "  <your-pi-ip> node.local"
echo "  <your-pi-ip> python.local"
echo ""
echo "Or use port-forwarding:"
echo "  kubectl port-forward -n apps svc/node-app 3000:3000"
echo "  kubectl port-forward -n apps svc/python-app 8000:8000"
echo ""

echo "================================"
echo "Useful Commands:"
echo "================================"
echo "View all resources:    kubectl get all -A"
echo "View logs:             kubectl logs -f <pod-name> -n <namespace>"
echo "Describe pod:          kubectl describe pod <pod-name> -n <namespace>"
echo "Execute command:       kubectl exec -it <pod-name> -n <namespace> -- sh"
echo "Delete deployment:     kubectl delete -f manifests/"
echo "Restart deployment:    kubectl rollout restart deployment/<name> -n <namespace>"
echo ""

echo "================================"
echo "Port Forward Apps (optional):"
echo "================================"
read -p "Start port forwarding? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting port forwarding... (Press Ctrl+C to stop)"
    echo ""
    kubectl port-forward -n apps svc/node-app 3000:3000 &
    kubectl port-forward -n apps svc/python-app 8000:8000 &
    echo ""
    echo "Access apps at:"
    echo "  Node.js: http://localhost:3000"
    echo "  Python:  http://localhost:8000"
    echo ""
    echo "Press Ctrl+C to stop port forwarding"
    wait
fi

echo ""
echo "Happy Kubernetes learning! 🚀"
