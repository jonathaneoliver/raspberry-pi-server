# Graphical Kubernetes Management Tools

## Option 1: Lens Desktop (Recommended)

Lens is the best Kubernetes IDE - free and feature-rich.

### Installation on Mac:

```bash
brew install --cask lens
```

Or download from: https://k8slens.dev/

### Connect to Your Pi Cluster:

1. Copy the kubeconfig from your Pi to your Mac:
   ```bash
   scp pi@raspberrypi.local:~/.kube/config ~/.kube/config-pi
   ```

2. Merge it with your local config (if you have one):
   ```bash
   # Backup existing config
   cp ~/.kube/config ~/.kube/config.backup 2>/dev/null || true
   
   # Use the Pi config
   mkdir -p ~/.kube
   cp ~/.kube/config-pi ~/.kube/config
   ```

3. Open Lens, click "Add Cluster" → it will auto-detect your cluster

### Features:
- Visual pod/deployment monitoring
- Real-time logs viewer
- Shell into containers
- Resource usage graphs
- Easy scaling (drag slider)
- Port forwarding with one click

## Option 2: k9s (Terminal UI - Fast)

Best terminal-based Kubernetes UI.

### Installation:

```bash
brew install k9s
```

### Usage:

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Launch k9s
k9s
```

### Navigation:
- `:pods` - view pods
- `:deployments` - view deployments
- `:services` - view services
- `l` - view logs
- `d` - describe resource
- `s` - shell into pod
- `/` - search
- `?` - help

## Option 3: Kubernetes Dashboard (Web UI)

Official Kubernetes web interface.

### Install on Pi:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

### Create admin user:

```bash
# On your Pi
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

### Get access token:

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

### Access from Mac:

```bash
# Port forward to your Mac
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443

# Open in browser
open https://localhost:8443
```

Use the token from above to login.

## Option 4: Portainer (Docker-style UI)

Works with Kubernetes too!

### Install on Pi:

```bash
kubectl apply -n portainer -f https://downloads.portainer.io/ce2-19/portainer.yaml
```

### Access:

```bash
# Port forward
kubectl port-forward -n portainer svc/portainer 9443:9443

# Open
open https://localhost:9443
```

## Option 5: Rancher (Full Platform)

Complete Kubernetes management platform.

### Install on Pi:

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.local \
  --set bootstrapPassword=admin
```

Access at `https://raspberrypi.local`

## Quick Setup Script

Run this on your Mac to set up Lens:

```bash
#!/bin/bash

echo "Setting up Kubernetes management from Mac..."

# Install Lens
brew install --cask lens || echo "Lens already installed"

# Copy kubeconfig from Pi
echo "Copying kubeconfig from Pi..."
mkdir -p ~/.kube
scp pi@raspberrypi.local:~/.kube/config ~/.kube/config

# Test connection
kubectl get nodes

echo "✅ Setup complete!"
echo "Open Lens to see your cluster"
```

## My Recommendation

For your learning setup, I recommend:

1. **Start with k9s** (quick, lightweight)
   ```bash
   brew install k9s
   scp pi@raspberrypi.local:~/.kube/config ~/.kube/config
   k9s
   ```

2. **Then install Lens** (best full-featured GUI)
   ```bash
   brew install --cask lens
   ```

3. **Optional: Kubernetes Dashboard** (official web UI)

## Deploying New Apps

Once you have the GUI:

### Via Lens:
1. Click "+" → "Create Resource"
2. Paste your YAML or select files
3. Click "Create"

### Via k9s:
1. Press `:` to enter command mode
2. Type `pods` and press Enter
3. Navigate and press `l` for logs, `d` for describe

### Via kubectl (from Mac):
```bash
# Deploy a new app
kubectl apply -f my-app.yaml

# Watch deployment
kubectl get pods -w

# Check logs
kubectl logs -f deployment/my-app
```

Would you like me to create the setup script for you?
