# Raspberry Pi 5 Self-Hosting Server

A comprehensive learning setup for self-hosting applications on Raspberry Pi 5, featuring both **Docker Compose** and **Kubernetes (K3s)** approaches for comparison.

## What's Included

This project provides a complete, production-ready setup with:

- **Two deployment approaches**: Docker Compose and K3s (Kubernetes)
- **Sample applications**: Node.js (Express) and Python (FastAPI)
- **Databases**: PostgreSQL, Redis
- **Reverse Proxy**: Traefik with automatic SSL
- **Management UIs**: Portainer (Docker), Rancher (K3s)
- **Monitoring**: Prometheus + Grafana (K3s)
- **CI/CD examples**: GitHub Actions workflows
- **Auto-updates**: Watchtower (Docker), ArgoCD (K3s)

## Quick Start

### Prerequisites

- Raspberry Pi 5 (4GB+ RAM recommended)
- Raspberry Pi OS Lite (64-bit) or Ubuntu Server 22.04 ARM64
- SSH access to your Pi
- Domain name (optional, for SSL certificates)

### Initial Setup

1. **Clone this repository to your Pi:**
   ```bash
   git clone <your-repo-url>
   cd server
   ```

2. **Run the initial setup script:**
   ```bash
   chmod +x scripts/pi-setup.sh
   sudo ./scripts/pi-setup.sh
   ```

3. **Choose your approach:**
   - [Docker Compose Setup](#docker-compose-setup) - Simpler, lower overhead
   - [K3s Setup](#k3s-setup) - Kubernetes experience, more features

## Docker Compose Setup

Perfect for: Simple deployments, lower resource usage, easier troubleshooting

```bash
cd docker-compose
cp .env.example .env
# Edit .env with your settings
nano .env

# Deploy everything
./deploy.sh
```

**Access points:**
- Portainer UI: `http://<pi-ip>:9000`
- Node.js app: `http://<pi-ip>:3000`
- Python app: `http://<pi-ip>:8000`
- Traefik dashboard: `http://<pi-ip>:8080`

See [docker-compose/README.md](docker-compose/README.md) for details.

## K3s Setup

Perfect for: Learning Kubernetes, multi-node clusters, advanced orchestration

```bash
cd k3s
# Install K3s
sudo ./install.sh

# Deploy applications
./deploy.sh
```

**Access points:**
- Rancher UI: `https://<pi-ip>:8443`
- Applications via ingress: Configure DNS or use `/etc/hosts`
- ArgoCD: `https://<pi-ip>:30443`

See [k3s/README.md](k3s/README.md) for details.

## Architecture Comparison

| Feature | Docker Compose | K3s (Kubernetes) |
|---------|---------------|------------------|
| **Complexity** | Simple | Moderate |
| **Resource Usage** | ~500MB RAM | ~1GB RAM |
| **Learning Curve** | Gentle | Steeper |
| **Scalability** | Single node | Multi-node ready |
| **Auto-healing** | Limited | Built-in |
| **Industry Standard** | Common | Very common |
| **Configuration** | docker-compose.yml | YAML manifests |
| **Management UI** | Portainer | Rancher/Lens |
| **Best For** | Quick deployments | Production clusters |

See [docs/COMPARISON.md](docs/COMPARISON.md) for detailed comparison.

## Sample Applications

### Node.js Application
- Express.js REST API
- PostgreSQL connection
- Health checks
- Environment configuration

### Python Application
- FastAPI REST API
- PostgreSQL connection
- Async support
- OpenAPI documentation

Both apps are identical in functionality to demonstrate deployment differences.

## Deployment Workflows

### Docker Compose Deployment
```bash
# Local development
cd apps/node-app
docker build -t node-app:latest .

# Push to Docker Hub (optional)
docker tag node-app:latest yourusername/node-app:latest
docker push yourusername/node-app:latest

# Deploy on Pi
cd docker-compose
docker-compose pull
docker-compose up -d
```

### K3s Deployment
```bash
# Build and push image
cd apps/node-app
docker build -t node-app:latest .
docker tag node-app:latest yourusername/node-app:latest
docker push yourusername/node-app:latest

# Deploy to K3s
kubectl apply -f k3s/manifests/deployments/node-app.yaml

# Or use ArgoCD for GitOps
# Just push to Git and ArgoCD auto-deploys
```

See [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) for detailed workflows.

## CI/CD Integration

Both approaches include GitHub Actions workflows:

- **Docker Compose**: Builds images, pushes to registry, SSH deploys to Pi
- **K3s**: Builds images, pushes to registry, updates K8s manifests, ArgoCD auto-syncs

See [ci-cd/README.md](ci-cd/README.md) for setup instructions.

## Resource Monitoring

### Docker Compose
```bash
docker stats
```

### K3s
```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

Access Grafana dashboards at `http://<pi-ip>:3000` (K3s only)

## Backup & Recovery

```bash
# Backup databases and configurations
./scripts/backup.sh

# Backups stored in ./backups/
```

## Migrating Between Approaches

Want to switch from Docker Compose to K3s or vice versa?

See [docs/MIGRATION.md](docs/MIGRATION.md) for step-by-step migration guide.

## Project Structure

```
.
├── README.md                          # This file
├── SETUP.md                           # Initial Pi setup guide
├── docker-compose/                    # Docker Compose approach
│   ├── docker-compose.yml            # Service definitions
│   ├── deploy.sh                     # Deployment script
│   └── services/                     # Service configurations
├── k3s/                              # Kubernetes approach
│   ├── install.sh                    # K3s installation
│   ├── deploy.sh                     # Deployment script
│   └── manifests/                    # Kubernetes YAML files
├── apps/                             # Sample applications
│   ├── node-app/                     # Express.js app
│   └── python-app/                   # FastAPI app
├── scripts/                          # Utility scripts
├── ci-cd/                            # CI/CD workflows
└── docs/                             # Documentation
```

## Learning Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

See [docs/LEARNING.md](docs/LEARNING.md) for curated learning path.

## Troubleshooting

Common issues and solutions in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Performance Tips

- Use lightweight base images (Alpine, Distroless)
- Enable Docker BuildKit for faster builds
- Use multi-stage builds
- Limit container resources
- Enable swap on Pi (carefully)
- Use SSD instead of SD card for better I/O

## Security Considerations

- Change default passwords
- Use secrets management (Docker Secrets / K8s Secrets)
- Enable firewall (UFW)
- Keep system updated
- Use non-root containers
- Enable SSL/TLS with Let's Encrypt

See [docs/SECURITY.md](docs/SECURITY.md) for security hardening guide.

## Contributing

This is a learning project! Feel free to:
- Add more sample applications
- Improve documentation
- Share your configurations
- Report issues

## License

MIT License - Feel free to use and modify for your learning journey!

## Next Steps

1. Complete initial setup: [SETUP.md](SETUP.md)
2. Choose Docker Compose or K3s
3. Deploy sample applications
4. Explore management UIs
5. Try deploying your own apps
6. Experiment with CI/CD
7. Compare resource usage and performance

Happy self-hosting!
