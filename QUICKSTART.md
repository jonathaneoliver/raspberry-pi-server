# Quick Start Guide

Get up and running on your Raspberry Pi 5 in under 30 minutes!

## Prerequisites

- Raspberry Pi 5 with Raspberry Pi OS or Ubuntu Server installed
- SSH access to your Pi
- Internet connection

## Option 1: Docker Compose (Recommended for Beginners)

### Step 1: Initial Setup (5 minutes)

```bash
# SSH into your Pi
ssh pi@raspberrypi.local

# Clone this repository
git clone <your-repo-url>
cd server

# Run setup script
chmod +x scripts/pi-setup.sh
sudo ./scripts/pi-setup.sh

# Log out and back in (for Docker group changes)
exit
ssh pi@raspberrypi.local
cd server
```

### Step 2: Configure Environment (2 minutes)

```bash
cd docker-compose
cp .env.example .env
nano .env  # Edit passwords and configuration
```

Change at minimum:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`

### Step 3: Deploy (5 minutes)

```bash
./deploy.sh
```

### Step 4: Access Your Services

- **Portainer**: http://raspberrypi.local:9000
- **Node.js App**: http://raspberrypi.local:3000
- **Python App**: http://raspberrypi.local:8000
- **Traefik Dashboard**: http://raspberrypi.local:8080

First time in Portainer:
1. Create admin account
2. Select "Docker" environment
3. Click "Connect"

## Option 2: Kubernetes (K3s) (For Learning K8s)

### Step 1: Initial Setup (same as above)

```bash
ssh pi@raspberrypi.local
git clone <your-repo-url>
cd server
chmod +x scripts/pi-setup.sh
sudo ./scripts/pi-setup.sh
```

### Step 2: Install K3s (10 minutes)

```bash
cd k3s
sudo ./install.sh

# Wait for installation to complete
kubectl get nodes  # Should show your Pi as Ready
```

### Step 3: Build and Deploy (10 minutes)

```bash
# Build app images locally
cd ../apps/node-app
docker build -t node-app:latest .

cd ../python-app
docker build -t python-app:latest .

# Deploy to K3s
cd ../../k3s
./deploy.sh
```

### Step 4: Access Your Services

Add to `/etc/hosts` on your computer:
```
<pi-ip-address> node.local python.local
```

Or use port-forwarding:
```bash
kubectl port-forward -n apps svc/node-app 3000:3000
kubectl port-forward -n apps svc/python-app 8000:8000
```

Then access:
- **Node.js App**: http://localhost:3000
- **Python App**: http://localhost:8000

## Testing Your Deployment

### Test Node.js App

```bash
# Health check
curl http://localhost:3000/health

# Get users
curl http://localhost:3000/users

# Get posts
curl http://localhost:3000/posts

# Get stats
curl http://localhost:3000/stats

# Create a user
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com"}'
```

### Test Python App

```bash
# Health check
curl http://localhost:8000/health

# API docs (FastAPI auto-generated)
open http://localhost:8000/docs

# Get users
curl http://localhost:8000/users

# Get posts
curl http://localhost:8000/posts
```

## Common Commands

### Docker Compose

```bash
# View logs
docker compose logs -f

# Restart a service
docker compose restart node-app

# Stop everything
docker compose down

# Update and restart
docker compose pull
docker compose up -d
```

### K3s

```bash
# View logs
kubectl logs -f deployment/node-app -n apps

# View all pods
kubectl get pods -A

# View services
kubectl get svc -A

# Restart deployment
kubectl rollout restart deployment/node-app -n apps

# Scale deployment
kubectl scale deployment/node-app --replicas=3 -n apps
```

## Troubleshooting

### Docker Compose Not Starting

```bash
# Check Docker is running
sudo systemctl status docker

# View container logs
docker compose logs

# Rebuild if needed
docker compose build
docker compose up -d
```

### K3s Pods Not Starting

```bash
# Check pod status
kubectl get pods -A

# Describe pod to see errors
kubectl describe pod <pod-name> -n apps

# Check logs
kubectl logs <pod-name> -n apps

# Check if images are present
sudo k3s crictl images
```

### Can't Access Services

```bash
# Check if services are running
docker compose ps  # Docker Compose
kubectl get pods -n apps  # K3s

# Check firewall
sudo ufw status

# Test locally on Pi
curl http://localhost:3000/health
```

### Out of Space

```bash
# Clean Docker
docker system prune -a -f

# Clean K3s
sudo k3s crictl rmi --prune
```

## Next Steps

1. **Explore the apps**: Try creating users and posts via the APIs
2. **Check the docs**: Read [COMPARISON.md](docs/COMPARISON.md) to understand differences
3. **Try CI/CD**: Set up GitHub Actions following [ci-cd/README.md](ci-cd/README.md)
4. **Deploy your own app**: Use the sample apps as templates
5. **Add monitoring**: Set up Grafana dashboards
6. **Experiment**: Try scaling, updating, rolling back

## Learning Path

**Week 1: Docker Compose**
- Deploy with Docker Compose
- Understand the docker-compose.yml
- Add a new service
- Set up CI/CD

**Week 2: Kubernetes**
- Install K3s
- Deploy same apps to K3s
- Compare resource usage
- Learn kubectl basics

**Week 3: Advanced Topics**
- Implement monitoring
- Add Ingress with SSL
- Try GitOps with ArgoCD
- Set up multi-node cluster (if you have more Pis)

## Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)

## Getting Help

If you run into issues:
1. Check the [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) guide
2. Review logs (docker logs / kubectl logs)
3. Check GitHub issues
4. Ask in Raspberry Pi or Kubernetes communities

Happy learning and self-hosting!
