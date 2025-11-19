# K3s Installation Issues - Quick Fixes

If K3s fails to start, try these solutions:

## 1. Enable Memory Cgroups (Most Common Issue)

K3s requires memory cgroups to be enabled. Check if they're enabled:

```bash
cat /boot/firmware/cmdline.txt
# or
cat /boot/cmdline.txt
```

If you don't see `cgroup_memory=1`, add it:

```bash
# Backup first
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup

# Edit the file
sudo nano /boot/firmware/cmdline.txt
```

Add to the END of the single line (don't create new lines):
```
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

Save and reboot:
```bash
sudo reboot
```

After reboot, run the troubleshooting script:
```bash
chmod +x scripts/k3s-troubleshoot.sh
./scripts/k3s-troubleshoot.sh
```

## 2. Check Service Logs

```bash
sudo systemctl status k3s
sudo journalctl -xeu k3s.service -n 100
```

## 3. Port Conflicts

Check if port 6443 is already in use:
```bash
sudo lsof -i :6443
```

## 4. Clean Install

If all else fails, completely remove and reinstall:

```bash
# Uninstall K3s
/usr/local/bin/k3s-uninstall.sh

# Clean up directories
sudo rm -rf /var/lib/rancher
sudo rm -rf /etc/rancher

# Reboot
sudo reboot

# After reboot, reinstall
cd k3s
sudo ./install.sh
```

## 5. Alternative: Use Docker Compose Instead

If K3s continues to have issues, you can use Docker Compose which is simpler and more reliable for single-node setups:

```bash
cd ../docker-compose
./deploy.sh
```

## Common Error Messages and Fixes

### "failed to find memory cgroup"
**Solution:** Enable cgroups (see #1 above)

### "port 6443 already in use"
**Solution:** Kill the process using the port or use a different port

### "permission denied"
**Solution:** Make sure you're running with `sudo ./install.sh`

### "dial tcp: lookup on...: no such host"
**Solution:** DNS issue, check `/etc/resolv.conf`

## Need More Help?

Run the troubleshooting script:
```bash
./scripts/k3s-troubleshoot.sh
```

Check the comparison guide to understand if K3s is the right choice:
```bash
cat docs/COMPARISON.md
```
