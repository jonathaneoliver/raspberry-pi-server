# Quick Start: Cloudflare Tunnel

This is a quick reference guide for setting up Cloudflare Tunnel. For detailed documentation, see [CLOUDFLARE-TUNNEL.md](./CLOUDFLARE-TUNNEL.md).

## Prerequisites (5 minutes)

### 1. Get a Domain
- Purchase a domain or use a free service
- Common registrars: Namecheap, Google Domains, Cloudflare

### 2. Set Up Cloudflare (Free)
1. Sign up at https://dash.cloudflare.com
2. Click "Add a Site"
3. Enter your domain name
4. Select the Free plan
5. Update your domain's nameservers to Cloudflare's
   - This is done at your domain registrar
   - Wait 5-60 minutes for DNS propagation

### 3. Create Cloudflare Tunnel
1. Go to https://one.dash.cloudflare.com
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared**
5. Name it: `raspberry-pi-home`
6. Click **Save tunnel**
7. **COPY THE TOKEN** (starts with `ey...`) - you'll need this!
8. Don't close the page yet - continue to step 4

### 4. Configure Public Hostnames

In the Cloudflare Tunnel configuration page, add public hostnames:

**For services running behind Traefik:**

| Subdomain | Service | Type | URL |
|-----------|---------|------|-----|
| `app.yourdomain.com` | Node App | HTTP | `http://traefik:80` |
| `api.yourdomain.com` | Python App | HTTP | `http://traefik:80` |
| `traefik.yourdomain.com` | Traefik UI | HTTP | `http://traefik:8080` |

**Important:** 
- Replace `yourdomain.com` with your actual domain
- All services route through Traefik (port 80)
- Traefik handles internal routing based on hostname

Click **Save tunnel** when done.

## Installation

### Option A: Docker Compose (Simpler)

```bash
# On your Raspberry Pi
cd /path/to/server
bash scripts/setup-cloudflare-docker.sh
```

The script will:
- Prompt for your tunnel token
- Update `.env` file
- Deploy cloudflared container
- Show verification steps

### Option B: K3s (Kubernetes)

```bash
# On your Raspberry Pi
cd /path/to/server
bash scripts/setup-cloudflare-k3s.sh
```

The script will:
- Prompt for your tunnel token
- Create Kubernetes secret
- Deploy cloudflared pods
- Show verification steps

## Verification (2 minutes)

### 1. Check Tunnel Status

**Cloudflare Dashboard:**
- Go to https://one.dash.cloudflare.com → Access → Tunnels
- Your tunnel should show **HEALTHY** with a green indicator

**Container Logs:**
```bash
# Docker Compose
docker logs cloudflared

# K3s
kubectl logs -n kube-system -l app=cloudflared
```

Look for: `Connection established` and `Registered tunnel connection`

### 2. Test Your Services

```bash
# Replace with your actual domain
curl https://app.yourdomain.com
curl https://api.yourdomain.com
```

Or open in a browser:
- https://app.yourdomain.com
- https://api.yourdomain.com

**Expected:** You should see your Node.js or Python app response

### 3. Verify HTTPS

Check the padlock icon in your browser - should show valid SSL certificate issued by Cloudflare.

## Troubleshooting

### Tunnel shows "Unhealthy"
```bash
# Check if cloudflared is running
docker ps | grep cloudflared
# or
kubectl get pods -n kube-system | grep cloudflared

# Check logs
docker logs cloudflared
# or
kubectl logs -n kube-system -l app=cloudflared --tail=100
```

**Common causes:**
- Wrong tunnel token
- Network connectivity issues
- Firewall blocking outbound connections on port 443

### 502 Bad Gateway
- Verify your services are running: `docker ps` or `kubectl get pods`
- Check Traefik is accessible: `curl http://localhost:80`
- Verify public hostname configuration in Cloudflare matches your service names

### DNS Not Resolving
- Wait 5-10 minutes for DNS propagation
- Clear DNS cache: `sudo dscacheutil -flushcache` (Mac) or `sudo systemd-resolve --flush-caches` (Linux)
- Try: `nslookup app.yourdomain.com 1.1.1.1`

### Connection Timeout
- Ensure Raspberry Pi has internet access
- Check no firewall blocking outbound HTTPS (port 443)
- Verify token is correct

## What's Happening?

```
Internet → Cloudflare Edge → Cloudflare Tunnel (outbound connection)
    ↓
Your Raspberry Pi (cloudflared container)
    ↓
Traefik (port 80) → Routes to correct service based on hostname
    ↓
Your Application (Node.js, Python, etc.)
```

**Key Points:**
- No inbound ports needed on your router
- All traffic encrypted with HTTPS
- Cloudflare provides DDoS protection
- Works behind any NAT/firewall setup

## Next Steps

### Add More Services
1. Deploy new service to your Pi
2. Add Traefik labels/ingress rules
3. Add public hostname in Cloudflare Tunnel
4. Test access via your domain

### Secure Admin Interfaces
Use Cloudflare Access to add authentication:
1. Go to https://one.dash.cloudflare.com
2. Navigate to **Access** → **Applications**
3. Create application for admin services
4. Add authentication (email, Google, GitHub, etc.)

### Monitor Traffic
- View analytics in Cloudflare dashboard
- See requests, bandwidth, and threats blocked
- Set up alerts for downtime

### Enable Caching
For static content:
1. Go to Cloudflare dashboard → Caching
2. Configure cache rules
3. Purge cache when deploying updates

## Resources

- [Full Documentation](./CLOUDFLARE-TUNNEL.md)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [Zero Trust Dashboard](https://one.dash.cloudflare.com)

## Cost

Everything is **FREE**:
- ✅ Cloudflare account (free plan)
- ✅ Cloudflare Tunnel (unlimited)
- ✅ SSL certificates (automatic)
- ✅ DDoS protection (basic)
- ✅ DNS hosting

**Only cost:** Domain name (~$10-15/year)
