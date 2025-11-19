# Cloudflare Tunnel Setup

This guide will help you expose your Raspberry Pi services to the internet using Cloudflare Tunnel, even behind multiple routers (double NAT).

## What is Cloudflare Tunnel?

Cloudflare Tunnel creates a secure, outbound-only connection from your Pi to Cloudflare's network. No port forwarding needed!

**Benefits:**
- ✅ Works behind any NAT/firewall
- ✅ Free with Cloudflare account
- ✅ Automatic HTTPS with valid certificates
- ✅ DDoS protection included
- ✅ Custom domain support
- ✅ No open ports on your router

## Prerequisites

### 1. Domain Name
You need a domain name pointed to Cloudflare's nameservers:
- Purchase a domain (Namecheap, Google Domains, etc.)
- Or use a free domain service like FreeDNS
- Add the domain to Cloudflare (free plan is fine)

### 2. Cloudflare Account
- Sign up at https://dash.cloudflare.com
- Add your domain to Cloudflare
- Update your domain's nameservers to Cloudflare's

### 3. Cloudflare Tunnel Token
Follow these steps to create a tunnel:

1. Go to https://one.dash.cloudflare.com
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** as the connector
5. Name your tunnel (e.g., "raspberry-pi-home")
6. Click **Save tunnel**
7. **Copy the tunnel token** (starts with `ey...`)
8. Configure your public hostnames (see below)

## Public Hostname Configuration

In the Cloudflare dashboard, configure these public hostnames:

| Service | Subdomain | Type | URL |
|---------|-----------|------|-----|
| Node App | `node.yourdomain.com` | HTTP | `http://traefik:80` |
| Python App | `python.yourdomain.com` | HTTP | `http://traefik:80` |
| Traefik Dashboard | `traefik.yourdomain.com` | HTTP | `http://traefik:8080` |
| Portainer | `portainer.yourdomain.com` | HTTP | `http://portainer:9000` |

**Note:** We're routing through Traefik, which handles the internal routing to services.

## Setup Instructions

Choose your deployment method:

### Option A: Docker Compose
```bash
# 1. Set your tunnel token
export CF_TUNNEL_TOKEN="your-tunnel-token-here"

# 2. Update the .env file
echo "CF_TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}" >> docker/.env

# 3. Deploy with Cloudflare Tunnel
cd docker
docker-compose -f docker-compose.yml -f docker-compose.cloudflare.yml up -d
```

### Option B: Kubernetes (K3s)
```bash
# 1. Create the tunnel token secret
kubectl create secret generic cloudflare-tunnel \
  --from-literal=token=your-tunnel-token-here \
  -n kube-system

# 2. Deploy cloudflared
kubectl apply -f k3s/manifests/cloudflare/

# 3. Verify it's running
kubectl get pods -n kube-system | grep cloudflared
```

## Verification

### 1. Check Tunnel Status
In Cloudflare dashboard:
- Go to **Access** → **Tunnels**
- Your tunnel should show as **HEALTHY** with a green indicator

### 2. Test Your Services
```bash
# Replace yourdomain.com with your actual domain
curl https://node.yourdomain.com
curl https://python.yourdomain.com
```

### 3. Check Logs

**Docker Compose:**
```bash
docker logs cloudflared
```

**K3s:**
```bash
kubectl logs -n kube-system -l app=cloudflared
```

## Troubleshooting

### Tunnel Shows as Unhealthy
```bash
# Check if cloudflared is running
docker ps | grep cloudflared
# or
kubectl get pods -n kube-system | grep cloudflared

# Check logs for errors
docker logs cloudflared
# or
kubectl logs -n kube-system -l app=cloudflared
```

### 502 Bad Gateway
- Verify Traefik is running: `docker ps | grep traefik`
- Check that services are accessible internally
- Verify public hostname configuration in Cloudflare matches your services

### Connection Timeout
- Ensure your tunnel token is correct
- Check that cloudflared container has internet access
- Verify no firewall blocking outbound connections on port 443

### DNS Not Resolving
- Wait 5-10 minutes for DNS propagation
- Clear your DNS cache: `sudo dscacheutil -flushcache` (Mac)
- Try using a different DNS server (8.8.8.8)

## Security Considerations

### 1. Disable Direct Access (Optional)
Since you're using Cloudflare Tunnel, you may want to restrict Traefik to only accept connections from Cloudflare:

```bash
# Add these environment variables to Traefik
TRAEFIK_ENTRYPOINTS_WEB_FORWARDEDHEADERS_TRUSTEDIPS=173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22
```

### 2. Protect Admin Interfaces
Add Cloudflare Access (free) to protect Portainer, Traefik dashboard, etc.:
- Go to **Access** → **Applications**
- Create a new application
- Add authentication (email, Google, etc.)

### 3. Rate Limiting
Consider enabling Cloudflare's rate limiting rules to prevent abuse.

## Advanced: Multiple Tunnels

You can create multiple tunnels for different purposes:
- One for production services
- One for development/testing
- One for admin interfaces

Each tunnel gets its own token and can have different security policies.

## Cost

Everything described here uses Cloudflare's **free tier**:
- Free Cloudflare Tunnel
- Free DNS
- Free SSL certificates
- Free basic DDoS protection

You only pay for your domain name (~$10-15/year).

## Next Steps

Once your tunnel is working:
1. Set up Cloudflare Access for admin interfaces
2. Configure firewall rules in Cloudflare
3. Enable Web Application Firewall (WAF) rules
4. Set up analytics and monitoring in Cloudflare dashboard
5. Consider Cloudflare's caching rules for static content

## Resources

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflared Docker Image](https://hub.docker.com/r/cloudflare/cloudflared)
- [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com)
