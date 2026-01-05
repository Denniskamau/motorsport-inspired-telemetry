# 📊 Deployment Comparison: local-dev vs Raspberry Pi

## Overview

This document compares the two deployment options for the F1 telemetry platform.

## 🖥️ Local Development (kind)

**Location**: `local-dev/`

### Use Case
- ✅ **Testing and development**
- ✅ **Quick demos** without hardware
- ✅ **Iterating on changes** rapidly
- ✅ **Learning Kubernetes** without committing to hardware

### Architecture
```
Your Mac/PC
  ├── Docker Desktop
  ├── kind (Kubernetes in Docker)
  │   ├── 3 nodes (1 control-plane, 2 workers)
  │   ├── MinIO (in-cluster)
  │   ├── Prometheus
  │   ├── Grafana
  │   ├── Edge Simulator
  │   └── Ingestion Service
  └── Access: localhost:3XXXX ports
```

### Pros
- ✅ **Fast setup** (5 minutes)
- ✅ **No hardware needed**
- ✅ **Easy teardown** (`./teardown.sh`)
- ✅ **Multi-node testing** (simulates distributed cluster)
- ✅ **Free** (uses your existing computer)

### Cons
- ❌ **Not 24/7** (Mac sleeps/restarts)
- ❌ **No public access** (localhost only)
- ❌ **Can't share live** with recruiters
- ❌ **Resource-heavy** on laptop
- ❌ **Temporary** (not production-like)

### When to Use
- Developing features
- Testing configurations
- Creating screenshots/videos
- Learning before Pi deployment

## 🏠 Raspberry Pi (k3s)

**Location**: `raspberry-pi/`

### Use Case
- ✅ **Live demo** for job applications
- ✅ **24/7 uptime** to share with recruiters
- ✅ **Home lab experience** on CV
- ✅ **Production-like** environment
- ✅ **Cost-effective** cloud alternative

### Architecture
```
Internet
  ↓
Cloudflare Tunnel (TLS, Zero Trust)
  ↓
Raspberry Pi 4
  ├── k3s (Lightweight Kubernetes)
  ├── External SSD (/data)
  │   ├── MinIO storage (50GB+)
  │   ├── Prometheus TSDB
  │   └── k3s persistent data
  ├── All services running 24/7
  └── Public URLs (HTTPS)
```

### Pros
- ✅ **24/7 uptime** - Always accessible
- ✅ **Public URLs** - Share with anyone
- ✅ **Production-like** - Real hardware, real persistence
- ✅ **Home lab cred** - Impressive on CV
- ✅ **Low cost** - $5/month power
- ✅ **Secure** - Cloudflare Tunnel (no open ports)
- ✅ **Persistent** - Survives restarts

### Cons
- ❌ **Initial cost** - $150 hardware
- ❌ **Slower setup** - 30-60 minutes
- ❌ **Physical space** - Need place for Pi
- ❌ **Single node** - Can't test multi-node features
- ❌ **ARM architecture** - Some images need rebuilding

### When to Use
- Applying for jobs (live demo)
- Building portfolio
- Learning home lab skills
- Long-term running projects

## 📋 Feature Comparison

| Feature | local-dev (kind) | Raspberry Pi (k3s) |
|---------|------------------|---------------------|
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Cost (Initial)** | $0 | $150 |
| **Cost (Monthly)** | $0 | $5 |
| **Multi-node** | ✅ (3 nodes) | ❌ (single node) |
| **Public Access** | ❌ | ✅ (Cloudflare) |
| **Uptime** | Intermittent | 24/7 |
| **Storage** | Ephemeral | Persistent (SSD) |
| **Architecture** | x86_64 | ARM64 |
| **Teardown** | Easy (`./teardown.sh`) | Requires cleanup |
| **Resume Impact** | Minimal | **High** |
| **Production-like** | ❌ | ✅ |
| **Power Usage** | Laptop power | ~10W (~$5/mo) |
| **Portability** | Runs anywhere | Fixed location |

## 🔄 Migration Path

### From local-dev to Raspberry Pi

**Step 1: Test locally first**
```bash
cd local-dev
./setup.sh
# Verify everything works
./teardown.sh
```

**Step 2: Prepare Raspberry Pi**
```bash
# Follow raspberry-pi/RASPBERRY-PI-DEPLOYMENT.md
# Steps 1-3 (OS, SSD, k3s)
```

**Step 3: Build ARM64 images on Mac**
```bash
# Use buildx for cross-platform builds
docker buildx build --platform linux/arm64 \
  -t f1-edge-simulator:latest ./edge-simulator --load
docker buildx build --platform linux/arm64 \
  -t f1-ingestion-service:latest ./ingestion-service --load

# Save and transfer
docker save f1-edge-simulator:latest | gzip > edge-sim-arm64.tar.gz
docker save f1-ingestion-service:latest | gzip > ingestion-arm64.tar.gz
scp *.tar.gz pi@raspberrypi.local:~
```

**Step 4: Deploy on Pi**
```bash
# SSH to Pi
ssh pi@raspberrypi.local

# Clone repo
git clone https://github.com/yourusername/motorsport-inspired-telemetry.git
cd motorsport-inspired-telemetry/raspberry-pi

# Import images
gunzip -c ~/edge-sim-arm64.tar.gz | sudo k3s ctr images import -
gunzip -c ~/ingestion-arm64.tar.gz | sudo k3s ctr images import -

# Run setup
./setup-pi.sh
```

**Step 5: Setup Cloudflare Tunnel**
```bash
# Follow raspberry-pi/RASPBERRY-PI-DEPLOYMENT.md Step 5
```

## 💡 Recommended Workflow

### For Job Applications

**Phase 1: Development (local-dev)**
1. Use `local-dev/` to build and test features
2. Create demo video showing local dashboard
3. Take screenshots for documentation

**Phase 2: Production Demo (Raspberry Pi)**
1. Deploy to Raspberry Pi using `raspberry-pi/`
2. Setup Cloudflare Tunnel for public access
3. Share live URL in job application
4. Keep running 24/7 during interview process

**Phase 3: Interview**
1. Show live dashboard on phone during interview
2. Explain architecture (local dev → Pi production)
3. Discuss cost optimization (Pi vs AWS)
4. Demonstrate monitoring and observability

### Example Application Email

> **Subject**: Cloud Engineer Application - Live F1 Telemetry Demo
>
> Dear Hiring Manager,
>
> I'm excited to apply for the AWS Cloud Engineer position at Toyota Gazoo Racing Europe.
>
> To demonstrate my capabilities, I've built a motorsport-inspired telemetry platform showcasing:
> - ✅ Kubernetes deployment (k3s on Raspberry Pi home lab)
> - ✅ Edge-to-cloud data pipeline
> - ✅ Observability stack (Prometheus + Grafana)
> - ✅ Secure public exposure (Cloudflare Tunnel)
> - ✅ Cost optimization ($5/month vs $140/month AWS)
>
> **Live Demo**: https://f1-telemetry.yourname.com
> **Source Code**: https://github.com/yourname/motorsport-inspired-telemetry
> **Demo Video**: https://youtube.com/...
>
> The platform runs 24/7 on a Raspberry Pi home lab and demonstrates real-world cloud engineering skills applicable to motorsport operations.
>
> I'd love to discuss how I can bring this mindset to Toyota Gazoo Racing Europe.
>
> Best regards,
> [Your Name]

## 🎯 Which Should You Choose?

### Choose **local-dev** if:
- You're just starting to learn the project
- You need to iterate quickly
- You want to test changes frequently
- You haven't purchased a Raspberry Pi yet
- You're creating a video demo (can show locally)

### Choose **Raspberry Pi** if:
- You're applying for jobs NOW
- You want a live 24/7 demo
- You're building your home lab portfolio
- You want to learn production Kubernetes
- You need to share a public URL with recruiters
- You want to impress interviewers with real infrastructure

### Ideal: Use BOTH
1. **Develop locally** with `local-dev/` for speed
2. **Deploy to Pi** for production demo
3. **Keep Pi running** during job search
4. **Update Pi** when you make changes locally

## 📈 Resume Impact

### Mentioning local-dev
> "Built F1 telemetry platform with Kubernetes (kind), Prometheus, Grafana, and MinIO for local development and testing."

**Impact**: ⭐⭐⭐ (Good - Shows technical skills)

### Mentioning Raspberry Pi
> "Deployed production F1 telemetry platform on Raspberry Pi home lab with k3s Kubernetes, public access via Cloudflare Tunnel, and 99.5% uptime over 3 months. Live demo: https://f1-telemetry.yourname.com"

**Impact**: ⭐⭐⭐⭐⭐ (Excellent - Shows production skills + initiative)

## 🚀 Next Steps

1. **Start with local-dev** to learn the platform
   ```bash
   cd local-dev && ./setup.sh
   ```

2. **Test everything locally** and take screenshots

3. **Order Raspberry Pi** (~$150)

4. **Deploy to Pi** when hardware arrives
   ```bash
   cd raspberry-pi && ./setup-pi.sh
   ```

5. **Setup Cloudflare Tunnel** for public access

6. **Share in job applications** with live URL

---

**Both paths lead to success, but Raspberry Pi + Cloudflare Tunnel will make your application stand out significantly!** 🏎️
