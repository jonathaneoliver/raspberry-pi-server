#!/bin/bash

# Complete K3s Deployment Fix Script
# Handles all common issues

set -e

echo "================================"
echo "K3s Deployment Fix"
echo "================================"
echo ""

cd "$(dirname "$0")"

echo "1️⃣  Deleting existing deployments..."
kubectl delete namespace apps databases --ignore-not-found=true

echo ""
echo "⏳ Waiting for namespaces to be fully deleted..."
sleep 10

echo ""
echo "2️⃣  Building application images..."
if [ -d "../apps/node-app" ]; then
    echo "Building Node.js app..."
    docker build -t node-app:latest ../apps/node-app
else
    echo "❌ Node.js app directory not found!"
    exit 1
fi

if [ -d "../apps/python-app" ]; then
    echo "Building Python app..."
    docker build -t python-app:latest ../apps/python-app
else
    echo "❌ Python app directory not found!"
    exit 1
fi

echo ""
echo "3️⃣  Importing images to K3s..."
echo "Exporting Node.js image..."
docker save node-app:latest -o /tmp/node-app.tar

echo "Exporting Python image..."
docker save python-app:latest -o /tmp/python-app.tar

echo "Importing to K3s..."
sudo k3s ctr images import /tmp/node-app.tar
sudo k3s ctr images import /tmp/python-app.tar

echo "Cleaning up temp files..."
rm -f /tmp/node-app.tar /tmp/python-app.tar

echo ""
echo "4️⃣  Verifying images in K3s..."
sudo k3s crictl images | grep -E "(node-app|python-app)"

echo ""
echo "5️⃣  Creating namespaces..."
kubectl apply -f manifests/namespaces/

echo ""
echo "6️⃣  Creating ConfigMaps and Secrets..."
kubectl apply -f manifests/configmaps/

echo ""
echo "7️⃣  Deploying databases..."
kubectl apply -f manifests/deployments/apps.yaml

echo ""
echo "8️⃣  Creating services..."
kubectl apply -f manifests/services/

echo ""
echo "9️⃣  Creating ingress..."
kubectl apply -f manifests/ingress/

echo ""
echo "⏳ Waiting for pods to start..."
sleep 15

echo ""
echo "================================"
echo "Deployment Status"
echo "================================"
echo ""

echo "Databases:"
kubectl get pods -n databases

echo ""
echo "Applications:"
kubectl get pods -n apps

echo ""
echo "Services:"
kubectl get svc -n apps

echo ""
echo "================================"
echo "Checking Pod Health"
echo "================================"
echo ""

# Check if any pods are failing
FAILING_PODS=$(kubectl get pods -n apps --field-selector=status.phase!=Running,status.phase!=Succeeded -o name 2>/dev/null || true)

if [ -n "$FAILING_PODS" ]; then
    echo "⚠️  Some pods are not running. Describing first failing pod:"
    echo ""
    FIRST_FAILING=$(echo "$FAILING_PODS" | head -1)
    kubectl describe -n apps "$FIRST_FAILING"
    echo ""
    echo "To check logs:"
    echo "  kubectl logs -n apps $FIRST_FAILING"
else
    echo "✅ All pods are running!"
    echo ""
    echo "Access your apps:"
    echo "  kubectl port-forward -n apps svc/node-app 3000:3000"
    echo "  kubectl port-forward -n apps svc/python-app 8000:8000"
    echo ""
    echo "Then visit:"
    echo "  http://localhost:3000"
    echo "  http://localhost:8000"
fi

echo ""
echo "To watch pods:"
echo "  kubectl get pods -n apps -w"
echo ""
