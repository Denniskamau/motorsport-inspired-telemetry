# 🏎️ Raspberry Pi Home Lab Deployment

## 🎯 Architecture Overview

Deploy the F1 telemetry platform on a Raspberry Pi as a **home lab** with **public access** via Cloudflare Tunnel. Perfect for demonstrating 24/7 production-ready infrastructure for your Toyota Gazoo Racing Europe application.

```
Internet
  ↓
Cloudflare Tunnel (TLS, No open ports)
  ↓
Raspberry Pi 4 (8GB)
  ↓
k3s Kubernetes Cluster
  ├── Edge Simulator → Ingestion Service → MinIO (External SSD)
  ├── Prometheus
  └── Grafana (Publicly accessible dashboards)
```

## 🛠️ Hardware Requirements

### Required
- **Raspberry Pi 4** (8GB RAM recommended, 4GB minimum)
- **External SSD** (256GB+, USB 3.0 - AVOID SD card for data storage)
- **Power Supply** (Official 15W USB-C or better)
- **Ethernet Cable** (Wi-Fi works but not recommended for demos)
- **Case with Fan** (Important for thermal management)

### Optional but Recommended
- **Heatsinks** or active cooling
- **UPS** (for clean demos without power interruptions)

### Cost: ~$150-200 total (one-time)
- Pi 4 (8GB): ~$75
- External SSD (256GB): ~$30
- Power + Case + Accessories: ~$40

**vs AWS**: $100-150/month = ROI in 2 months

## 📦 Software Stack

### Base OS
**Raspberry Pi OS 64-bit Lite** (Recommended)
- Lightweight
- Official support
- ARM64 architecture

Alternative: **Ubuntu Server 22.04 LTS ARM64**

### Kubernetes
**k3s** (NOT kind or kubeadm)
- ARM-native
- Single-node optimized
- Production-grade
- 512MB footprint
- Built-in Traefik ingress

### Storage
- **Local-path provisioner** (included in k3s)
- External SSD mounted at `/data`
- MinIO stores telemetry on SSD

### Public Exposure
**Cloudflare Tunnel** (cloudflared)
- Zero cost
- No port forwarding
- Automatic TLS
- DDoS protection
- Public URL: `f1-telemetry.yourname.com`

## 🚀 Step-by-Step Setup

### Step 1: Prepare Raspberry Pi

#### 1.1 Flash OS
```bash
# Download Raspberry Pi Imager
# Select: Raspberry Pi OS (64-bit) Lite
# Configure:
#   - Set hostname: f1-telemetry
#   - Enable SSH
#   - Set username/password
#   - Configure Wi-Fi (if needed)
```

#### 1.2 Initial Setup (SSH into Pi)
```bash
ssh pi@f1-telemetry.local

# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y curl git vim htop

# Set timezone
sudo timedatectl set-timezone Europe/Amsterdam
```

### Step 2: Mount External SSD

#### 2.1 Format and Mount
```bash
# Find your SSD
lsblk
# Example output: /dev/sda

# Format as ext4 (WARNING: Destroys data!)
sudo mkfs.ext4 /dev/sda

# Create mount point
sudo mkdir -p /data

# Get UUID
sudo blkid /dev/sda
# Example: UUID="abc123..."

# Add to /etc/fstab for auto-mount
echo 'UUID=abc123... /data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Mount
sudo mount -a

# Verify
df -h /data
```

#### 2.2 Set Permissions
```bash
sudo chown -R $USER:$USER /data
mkdir -p /data/k3s-storage
```

### Step 3: Install k3s

#### 3.1 Install k3s with Custom Storage
```bash
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --data-dir /data/k3s-data \
  --disable traefik

# Wait for k3s to start
sudo systemctl status k3s

# Verify
kubectl get nodes
# Should show: f1-telemetry   Ready   control-plane,master
```

#### 3.2 Configure kubectl
```bash
# Copy kubeconfig to user home
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Verify
kubectl get pods -A
```

### Step 4: Deploy F1 Telemetry Platform

#### 4.1 Clone Repository
```bash
cd ~
git clone https://github.com/yourusername/motorsport-inspired-telemetry.git
cd motorsport-inspired-telemetry
```

#### 4.2 Update Configurations for k3s

Create k3s-specific storage class:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minio-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/k3s-storage/minio
  storageClassName: local-path
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 50Gi
EOF
```

#### 4.3 Build Docker Images (on Pi - may take 20 minutes)

**Option A: Build on Pi (slow but self-contained)**
```bash
cd ~/motorsport-inspired-telemetry

# Build images
docker build -t f1-edge-simulator:latest ./edge-simulator
docker build -t f1-ingestion-service:latest ./ingestion-service

# Import to k3s (k3s uses containerd, not Docker)
sudo k3s ctr images import $(docker save f1-edge-simulator:latest | sudo k3s ctr images import -)
sudo k3s ctr images import $(docker save f1-ingestion-service:latest | sudo k3s ctr images import -)
```

**Option B: Build on your Mac, push to Pi (faster)**
```bash
# On your Mac:
docker buildx build --platform linux/arm64 -t f1-edge-simulator:latest ./edge-simulator --load
docker buildx build --platform linux/arm64 -t f1-ingestion-service:latest ./ingestion-service --load
docker save f1-edge-simulator:latest | gzip > edge-sim.tar.gz
docker save f1-ingestion-service:latest | gzip > ingestion.tar.gz
scp *.tar.gz pi@f1-telemetry.local:~

# On Pi:
gunzip -c edge-sim.tar.gz | sudo k3s ctr images import -
gunzip -c ingestion.tar.gz | sudo k3s ctr images import -
```

#### 4.4 Deploy Services
```bash
cd ~/motorsport-inspired-telemetry/raspberry-pi/k8s

# Deploy in order
kubectl apply -f minio.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f kube-state-metrics.yaml
kubectl apply -f grafana.yaml
kubectl apply -f ingestion-service.yaml
kubectl apply -f edge-simulator.yaml

# Wait for all pods to be ready (may take 5-10 minutes)
watch kubectl get pods
```

#### 4.5 Verify Deployment
```bash
# Check all pods running
kubectl get pods

# Check services
kubectl get svc

# Test locally
curl http://localhost:30080/health  # Ingestion service
curl http://localhost:30030         # Grafana
curl http://localhost:30090         # Prometheus
```

### Step 5: Setup Cloudflare Tunnel

#### 5.1 Create Cloudflare Account
1. Go to [dash.cloudflare.com](https://dash.cloudflare.com)
2. Sign up (free tier is fine)
3. Add a domain (or use Cloudflare's free subdomain)

#### 5.2 Install cloudflared on Pi
```bash
# Download ARM64 binary
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Verify
cloudflared --version
```

#### 5.3 Authenticate and Create Tunnel
```bash
# Login (opens browser)
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create f1-telemetry

# Note the Tunnel ID (shown in output)
# Example: Created tunnel f1-telemetry with id abc-123-xyz

# Create config file
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

**Paste this config** (replace TUNNEL_ID and yourdomain.com):
```yaml
tunnel: TUNNEL_ID
credentials-file: /home/pi/.cloudflared/TUNNEL_ID.json

ingress:
  # Grafana - Main dashboard
  - hostname: f1-telemetry.yourdomain.com
    service: http://localhost:30030

  # Prometheus - Metrics (optional, can restrict access)
  - hostname: prometheus.f1-telemetry.yourdomain.com
    service: http://localhost:30090

  # MinIO Console (optional)
  - hostname: minio.f1-telemetry.yourdomain.com
    service: http://localhost:30901

  # Catch-all
  - service: http_status:404
```

#### 5.4 Configure DNS
```bash
# Route DNS to tunnel
cloudflared tunnel route dns f1-telemetry f1-telemetry.yourdomain.com
cloudflared tunnel route dns f1-telemetry prometheus.f1-telemetry.yourdomain.com
cloudflared tunnel route dns f1-telemetry minio.f1-telemetry.yourdomain.com
```

#### 5.5 Start Tunnel as Service
```bash
# Install as system service
sudo cloudflared service install

# Start service
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared

# Test
curl https://f1-telemetry.yourdomain.com
```

### Step 6: Configure Grafana for Public Access

#### 6.1 Update Grafana Security
```bash
kubectl edit deployment grafana
```

Change these environment variables:
```yaml
- name: GF_SERVER_ROOT_URL
  value: "https://f1-telemetry.yourdomain.com"
- name: GF_SECURITY_ADMIN_PASSWORD
  value: "STRONG_PASSWORD_HERE"  # Change from 'admin'!
- name: GF_AUTH_ANONYMOUS_ENABLED
  value: "true"
- name: GF_AUTH_ANONYMOUS_ORG_ROLE
  value: "Viewer"  # Read-only for public
```

#### 6.2 Restart Grafana
```bash
kubectl rollout restart deployment grafana
```

## 🎬 Demo URLs (After Setup)

Share these URLs in your job application:

- **Main Dashboard**: https://f1-telemetry.yourdomain.com
- **Prometheus**: https://prometheus.f1-telemetry.yourdomain.com
- **MinIO Console**: https://minio.f1-telemetry.yourdomain.com

**In your application email:**
> "I've deployed a live demo of the F1 telemetry platform running 24/7 on a Raspberry Pi home lab with public access via Cloudflare Tunnel. You can view the live dashboards at https://f1-telemetry.yourdomain.com (credentials: viewer/viewer for read-only access)."

## 📊 Monitoring Pi Health

Add Pi-specific metrics to Grafana:

#### 6.1 Install Node Exporter
```bash
# Download ARM64 binary
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-arm64.tar.gz
tar xvf node_exporter-*.tar.gz
sudo mv node_exporter-*/node_exporter /usr/local/bin/

# Create service
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=pi
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Start
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

#### 6.2 Update Prometheus Config
```bash
kubectl edit configmap prometheus-config
```

Add node_exporter job:
```yaml
- job_name: 'raspberry-pi'
  static_configs:
    - targets: ['localhost:9100']
```

#### 6.3 Import Pi Dashboard
Import Grafana dashboard ID **1860** (Node Exporter Full) to monitor:
- CPU temperature
- Disk I/O (important for SSD health)
- Memory pressure
- Network bandwidth
- System load

## 🔒 Security Best Practices

### 1. Change Default Passwords
```bash
# Grafana - done in Step 6.1
# MinIO
kubectl set env deployment/minio \
  MINIO_ROOT_USER=YOUR_USER \
  MINIO_ROOT_PASSWORD=YOUR_STRONG_PASSWORD
```

### 2. Restrict Prometheus Access
Only expose Grafana publicly, keep Prometheus internal-only:
```yaml
# In cloudflared config, comment out:
# - hostname: prometheus.f1-telemetry.yourdomain.com
```

### 3. Enable Firewall
```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
```

Note: No need to open ports 80/443! Cloudflare Tunnel handles this.

### 4. Automatic Updates
```bash
# Enable unattended upgrades
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📈 Maintenance

### Daily Checks
```bash
# Check cluster health
kubectl get pods

# Check tunnel status
sudo systemctl status cloudflared

# Check disk space
df -h /data

# Check Pi temperature
vcgencmd measure_temp
```

### Weekly Tasks
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Check logs for errors
kubectl logs -l app=ingestion-service --tail=100
```

### Monthly Tasks
```bash
# Restart services for updates
kubectl rollout restart deployment --all

# Check SSD health
sudo smartctl -a /dev/sda
```

## 🚨 Troubleshooting

### Pi Getting Hot (>70°C)
```bash
# Check temperature
watch -n 1 vcgencmd measure_temp

# Solutions:
# 1. Add heatsinks
# 2. Improve airflow
# 3. Reduce CPU limits in deployments
```

### Pods CrashLooping
```bash
# Check memory
free -h

# Check pod logs
kubectl describe pod POD_NAME

# Solution: Reduce replica counts or resource requests
```

### Tunnel Disconnecting
```bash
# Check cloudflared logs
sudo journalctl -u cloudflared -f

# Restart tunnel
sudo systemctl restart cloudflared
```

### Slow Performance
```bash
# Check if using SD card (DON'T!)
lsblk

# Check SSD I/O
iostat -x 1

# Solution: Ensure MinIO is on SSD, not SD card
```

## 💰 Cost Comparison

### Raspberry Pi Home Lab (This Setup)
- **Hardware**: $150-200 (one-time)
- **Power**: ~$5/month (10W × 24/7 × $0.12/kWh)
- **Cloudflare**: $0/month (free tier)
- **Total Year 1**: $210-260

### AWS Equivalent (local-dev architecture)
- **EKS**: $73/month (control plane)
- **EC2**: $30/month (t3.medium nodes)
- **EBS**: $10/month (storage)
- **Data Transfer**: $10/month
- **Load Balancer**: $18/month
- **Total Year 1**: $1,692

**Savings: ~$1,450/year** 💰

## 🎯 For Your Job Application

### In Your CV:
> **Home Lab Infrastructure**
> - Deployed production Kubernetes cluster on Raspberry Pi
> - Configured Cloudflare Tunnel for secure public exposure
> - Implemented persistent storage with external SSD
> - Achieved 99.5% uptime over 3 months
> - Cost optimization: $5/month vs $140/month AWS equivalent

### In Your Cover Letter:
> "To demonstrate my DevOps capabilities, I've built a live F1 telemetry platform running 24/7 on a Raspberry Pi home lab, publicly accessible at https://f1-telemetry.yourname.com. This showcases my ability to architect cost-effective, production-ready infrastructure using Kubernetes, observability tools, and secure network exposure."

### During Interview:
- Pull up the live dashboard on your phone
- Show real-time data flowing
- Explain the architecture
- Highlight cost optimization ($5/month vs AWS)
- Demonstrate security (Cloudflare Tunnel, no open ports)

## 📚 Additional Resources

- [k3s Documentation](https://docs.k3s.io/)
- [Cloudflare Tunnel Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/)

---

**Ready to build your home lab!** 🏎️🏠

This setup will make your job application stand out significantly. Good luck with Toyota Gazoo Racing Europe!
