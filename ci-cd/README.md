# CI/CD Setup for Raspberry Pi

Automated deployment pipelines for both Docker Compose and K3s approaches.

## Overview

This directory contains GitHub Actions workflows for automated building, testing, and deployment to your Raspberry Pi.

## Workflows

### 1. `docker-deploy.yml` - Docker Compose Deployment
- Triggers on push to `main` branch
- Builds ARM64 images for both apps
- Pushes to GitHub Container Registry
- SSHs into Pi and deploys via docker-compose
- Runs health checks

### 2. `k3s-deploy.yml` - Kubernetes Deployment
- Triggers on push to `main` branch
- Builds ARM64 images for both apps
- Pushes to GitHub Container Registry
- Updates K3s deployments
- Performs rolling updates
- Runs health checks

## Setup Instructions

### 1. Fork/Clone this Repository

```bash
git clone <your-repo>
cd server
```

### 2. Set Up GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions

Add these secrets:

- `PI_HOST`: Your Raspberry Pi's IP address or hostname
- `PI_USERNAME`: SSH username (usually `pi`)
- `PI_SSH_KEY`: Your SSH private key for Pi access

#### Generate SSH Key (if needed)

```bash
# On your computer
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/pi_deploy

# Copy public key to Pi
ssh-copy-id -i ~/.ssh/pi_deploy.pub pi@<pi-ip>

# Add private key to GitHub secrets
cat ~/.ssh/pi_deploy
# Copy the entire output to PI_SSH_KEY secret
```

### 3. Enable GitHub Container Registry

The workflows push images to `ghcr.io` (GitHub Container Registry).

No additional setup needed - it's automatically available!

Images will be at:
- `ghcr.io/<your-username>/<repo>/node-app:latest`
- `ghcr.io/<your-username>/<repo>/python-app:latest`

### 4. Update Image References

Update these files to use your registry:

**For Docker Compose** (`docker-compose/docker-compose.yml`):
```yaml
services:
  node-app:
    image: ghcr.io/<your-username>/<repo>/node-app:latest
  python-app:
    image: ghcr.io/<your-username>/<repo>/python-app:latest
```

**For K3s** (`k3s/manifests/deployments/apps.yaml`):
```yaml
containers:
- name: node-app
  image: ghcr.io/<your-username>/<repo>/node-app:latest
  imagePullPolicy: Always
```

### 5. Configure Pi to Pull from Registry

#### For Docker Compose:

```bash
# Log in to GitHub Container Registry on Pi
echo $GITHUB_TOKEN | docker login ghcr.io -u <your-username> --password-stdin
```

#### For K3s:

```bash
# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<your-username> \
  --docker-password=<github-token> \
  -n apps

# Update deployment to use secret
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "ghcr-secret"}]}' \
  -n apps
```

## Workflow Details

### Docker Compose Workflow

```yaml
Trigger → Build Images → Push to Registry → SSH to Pi → docker compose pull → docker compose up -d → Health Check
```

**Pros:**
- Simple pipeline
- Quick deployment
- Direct SSH control

**Cons:**
- Brief downtime during update
- No automatic rollback

### K3s Workflow

```yaml
Trigger → Build Images → Push to Registry → SSH to Pi → kubectl set image → Rolling Update → Health Check
```

**Pros:**
- Zero-downtime deployment
- Automatic rollback on failure
- Gradual rollout

**Cons:**
- More complex
- Requires K3s knowledge

## Manual Deployment

### Docker Compose

```bash
# On your computer
git push origin main

# Workflow runs automatically
# Check: Actions tab on GitHub
```

### K3s

```bash
# On your computer
git push origin main

# Or trigger manually
gh workflow run k3s-deploy.yml
```

## Local Testing

Test workflows locally with `act`:

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act -j build-and-push --secret-file .secrets
```

## Alternative: Self-hosted Runner

For faster builds (no need to transfer images), run GitHub Actions runner on the Pi:

```bash
# On your Pi
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-arm64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-arm64-2.311.0.tar.gz

# Configure
./config.sh --url https://github.com/<your-username>/<repo> --token <token>

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
```

Then update workflows:
```yaml
jobs:
  build-and-push:
    runs-on: self-hosted  # Instead of ubuntu-latest
```

## Monitoring Deployments

### View Workflow Logs

```bash
# List recent runs
gh run list

# View specific run
gh run view <run-id>

# Watch live
gh run watch
```

### On the Pi

```bash
# Docker Compose
docker compose logs -f

# K3s
kubectl logs -f deployment/node-app -n apps
kubectl get events -n apps --sort-by='.lastTimestamp'
```

## Rollback Procedures

### Docker Compose

```bash
# SSH to Pi
ssh pi@<pi-ip>

# Rollback to previous image
cd ~/server/docker-compose
docker tag ghcr.io/<user>/<repo>/node-app:previous ghcr.io/<user>/<repo>/node-app:latest
docker compose up -d
```

### K3s

```bash
# SSH to Pi
ssh pi@<pi-ip>

# Automatic rollback
kubectl rollout undo deployment/node-app -n apps
kubectl rollout undo deployment/python-app -n apps

# Or rollback to specific revision
kubectl rollout history deployment/node-app -n apps
kubectl rollout undo deployment/node-app --to-revision=2 -n apps
```

## Best Practices

1. **Use Semantic Versioning**
   ```yaml
   tags: |
     type=semver,pattern={{version}}
     type=semver,pattern={{major}}.{{minor}}
     type=sha
   ```

2. **Add Tests**
   ```yaml
   - name: Run tests
     run: |
       cd apps/node-app
       npm install
       npm test
   ```

3. **Separate Staging/Production**
   ```yaml
   on:
     push:
       branches:
         - main      # production
         - staging   # staging environment
   ```

4. **Use Branch Protection**
   - Require PR reviews
   - Require status checks to pass
   - Require branches to be up to date

5. **Monitor Deployments**
   - Set up Slack/Discord notifications
   - Use Grafana dashboards
   - Enable Prometheus alerts

## Troubleshooting

### Build fails with "no space left on device"

```bash
# On Pi, clean Docker
docker system prune -a -f
```

### SSH connection fails

```bash
# Test SSH manually
ssh -i ~/.ssh/pi_deploy pi@<pi-ip>

# Check Pi SSH config
sudo systemctl status ssh
```

### Image pull fails

```bash
# Re-login to registry
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin

# For K3s, recreate secret
kubectl delete secret ghcr-secret -n apps
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token> \
  -n apps
```

### Deployment succeeds but app doesn't work

```bash
# Check logs
docker compose logs node-app  # Docker Compose
kubectl logs deployment/node-app -n apps  # K3s

# Check health
curl http://localhost:3000/health
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [SSH Action](https://github.com/appleboy/ssh-action)
