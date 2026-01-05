# 🏎️ Raspberry Pi Home Lab Deployment

Deploy the F1 telemetry platform on a Raspberry Pi with public access via Cloudflare Tunnel.

## 📁 Files in This Directory

- **[RASPBERRY-PI-DEPLOYMENT.md](RASPBERRY-PI-DEPLOYMENT.md)** - Complete deployment guide
- **[setup-pi.sh](setup-pi.sh)** - Automated setup script
- **[cloudflare-tunnel-config.yaml](cloudflare-tunnel-config.yaml)** - Cloudflare Tunnel configuration template
- **k8s/** - Kubernetes manifests optimized for Raspberry Pi

## 🚀 Quick Start

### Prerequisites
1. Raspberry Pi 4 (4GB+ RAM)
2. External SSD mounted at `/data`
3. Raspberry Pi OS 64-bit installed
4. SSH access configured

### Automated Setup

```bash
# 1. SSH into your Pi
ssh pi@raspberrypi.local

# 2. Clone repository
git clone https://github.com/yourusername/motorsport-inspired-telemetry.git
cd motorsport-inspired-telemetry/raspberry-pi

# 3. Run setup script
./setup-pi.sh
```

This will:
- ✅ Install k3s Kubernetes
- ✅ Deploy all services (MinIO, Prometheus, Grafana, Edge Simulator, Ingestion Service)
- ✅ Configure persistent storage on your external SSD
- ✅ Wait for all pods to be ready

### Manual Setup

Follow the detailed guide: [RASPBERRY-PI-DEPLOYMENT.md](RASPBERRY-PI-DEPLOYMENT.md)

## 🌐 Public Access with Cloudflare Tunnel

After local setup is complete:

```bash
# 1. Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# 2. Login and create tunnel
cloudflared tunnel login
cloudflared tunnel create f1-telemetry

# 3. Copy and edit config
sudo mkdir -p /etc/cloudflared
sudo cp cloudflare-tunnel-config.yaml /etc/cloudflared/config.yml
sudo nano /etc/cloudflared/config.yml
# Replace TUNNEL_ID and yourdomain.com

# 4. Route DNS
cloudflared tunnel route dns f1-telemetry f1-telemetry.yourdomain.com

# 5. Start tunnel service
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## 📊 Access Your Dashboard

**Local (from the Pi):**
- Grafana: http://localhost:30030
- Prometheus: http://localhost:30090
- MinIO: http://localhost:30901

**Public (after Cloudflare Tunnel setup):**
- Grafana: https://f1-telemetry.yourdomain.com
- Prometheus: https://prometheus.f1-telemetry.yourdomain.com
- MinIO: https://minio.f1-telemetry.yourdomain.com

## 🎯 For Your Job Application

### Share This URL
After setup, share your live demo URL in your application:

> **Live Demo**: https://f1-telemetry.yourname.com
>
> _Running 24/7 on Raspberry Pi home lab with k3s Kubernetes, secured via Cloudflare Tunnel_

### Key Selling Points
- ✅ **24/7 uptime** - Real production environment
- ✅ **Cost-efficient** - $5/month vs $140/month AWS
- ✅ **Secure** - No open ports, Cloudflare Tunnel
- ✅ **Observable** - Full Prometheus + Grafana stack
- ✅ **Scalable** - Kubernetes-native architecture
- ✅ **Home lab experience** - Highly valued skill

## 🔍 Monitoring & Maintenance

### Check System Health
```bash
# Cluster status
kubectl get pods --all-namespaces

# Pi temperature
vcgencmd measure_temp

# Disk space
df -h /data

# Tunnel status
sudo systemctl status cloudflared
```

### View Logs
```bash
# Edge simulator
kubectl logs -f deployment/edge-simulator

# Ingestion service
kubectl logs -f deployment/ingestion-service

# Cloudflare tunnel
sudo journalctl -u cloudflared -f
```

### Restart Services
```bash
# Restart all deployments
kubectl rollout restart deployment --all

# Restart specific service
kubectl rollout restart deployment grafana

# Restart tunnel
sudo systemctl restart cloudflared
```

## 💡 Tips

### Reduce Resource Usage
If your Pi is struggling:

```bash
# Reduce edge simulator frequency
kubectl set env deployment/edge-simulator COLLECTION_INTERVAL=120

# Reduce ingestion replicas
kubectl scale deployment ingestion-service --replicas=1
```

### Improve Cooling
Monitor temperature:
```bash
watch -n 1 vcgencmd measure_temp
```

If consistently >60°C:
- Add heatsinks
- Improve case airflow
- Consider active cooling (fan)

### Backup Configuration
```bash
# Backup k3s data
sudo tar czf k3s-backup-$(date +%Y%m%d).tar.gz /data/k3s-data

# Backup telemetry data
sudo tar czf telemetry-backup-$(date +%Y%m%d).tar.gz /data/k3s-storage
```

## 🚨 Troubleshooting

### Pods not starting?
```bash
# Check node resources
kubectl top nodes

# Check pod details
kubectl describe pod POD_NAME

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Tunnel not connecting?
```bash
# Check tunnel status
cloudflared tunnel info f1-telemetry

# Test tunnel connectivity
cloudflared tunnel run --config /etc/cloudflared/config.yml f1-telemetry
```

### Slow performance?
```bash
# Ensure MinIO is using SSD, not SD card
kubectl exec deployment/minio -- df -h /data

# Check I/O wait
iostat -x 1
```

## 📚 Documentation

- **Full Deployment Guide**: [RASPBERRY-PI-DEPLOYMENT.md](RASPBERRY-PI-DEPLOYMENT.md)
- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **k3s Documentation**: https://docs.k3s.io/

## 💰 Cost Analysis

| Item | Cost |
|------|------|
| Raspberry Pi 4 (8GB) | $75 (one-time) |
| External SSD (256GB) | $30 (one-time) |
| Power + Accessories | $40 (one-time) |
| **Initial Investment** | **$145** |
| Monthly Power (~10W) | $5/month |
| Cloudflare Tunnel | $0/month |
| **Monthly Operating** | **$5/month** |

**vs AWS**: $140/month = **$1,680/year savings**

---

**Ready to impress Toyota Gazoo Racing Europe with your home lab!** 🏎️

Questions? Check the full guide: [RASPBERRY-PI-DEPLOYMENT.md](RASPBERRY-PI-DEPLOYMENT.md)
