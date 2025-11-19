#!/bin/bash

# Docker Compose Deployment Script
# Deploys all services to Raspberry Pi

set -e

echo "================================"
echo "Docker Compose Deployment Script"
echo "================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📝 Creating .env from .env.example..."
    cp .env.example .env
    echo "✅ .env created. Please edit it with your configuration:"
    echo "   nano .env"
    echo ""
    echo "Press Enter after editing .env to continue..."
    read
fi

# Load environment variables
source .env

echo "🔍 Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "Run: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed!"
    echo "Run: sudo apt install docker-compose-plugin"
    exit 1
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "⚠️  User is not in docker group. You may need sudo."
    echo "Add yourself: sudo usermod -aG docker $USER"
    echo "Then log out and back in."
fi

echo "✅ Prerequisites check passed"
echo ""

# Pull latest images (only external images, not custom builds)
echo "📥 Pulling latest images..."
docker compose pull traefik portainer postgres redis watchtower || echo "⚠️  Some images couldn't be pulled, continuing..."

echo ""
echo "🏗️  Building custom images..."
docker compose build --no-cache

echo ""
echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "🔍 Running health checks..."
echo ""

# Wait for postgres
echo "Checking PostgreSQL..."
until docker compose exec -T postgres pg_isready -U ${POSTGRES_USER:-admin} > /dev/null 2>&1; do
    echo "  Waiting for PostgreSQL..."
    sleep 2
done
echo "  ✅ PostgreSQL is ready"

# Wait for redis
echo "Checking Redis..."
until docker compose exec -T redis redis-cli -a ${REDIS_PASSWORD} ping > /dev/null 2>&1; do
    echo "  Waiting for Redis..."
    sleep 2
done
echo "  ✅ Redis is ready"

# Check Node.js app
echo "Checking Node.js app..."
sleep 5
if curl -sf http://localhost:3000/health > /dev/null; then
    echo "  ✅ Node.js app is healthy"
else
    echo "  ⚠️  Node.js app not responding yet (may still be starting)"
fi

# Check Python app
echo "Checking Python app..."
if curl -sf http://localhost:8000/health > /dev/null; then
    echo "  ✅ Python app is healthy"
else
    echo "  ⚠️  Python app not responding yet (may still be starting)"
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "================================"
echo "Access Points:"
echo "================================"
echo "Portainer:      http://localhost:9000"
echo "Traefik:        http://localhost:8080"
echo "Node.js App:    http://localhost:3000"
echo "Python App:     http://localhost:8000"
echo "PostgreSQL:     localhost:5432"
echo "Redis:          localhost:6379"
echo ""
echo "================================"
echo "Useful Commands:"
echo "================================"
echo "View logs:       docker compose logs -f [service]"
echo "Restart:         docker compose restart [service]"
echo "Stop all:        docker compose down"
echo "Status:          docker compose ps"
echo "Shell access:    docker compose exec [service] sh"
echo ""
echo "================================"
echo "First Time Setup:"
echo "================================"
echo "1. Visit Portainer at http://localhost:9000"
echo "2. Create admin account"
echo "3. Connect to local Docker environment"
echo ""
echo "Happy hosting! 🚀"
