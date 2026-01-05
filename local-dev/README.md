# F1 Telemetry Platform - Local Demo Environment

Run the complete F1 telemetry platform locally using kind, MinIO, Prometheus, and Grafana - perfect for demonstrations and portfolio showcases!

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Docker Desktop** (https://www.docker.com/products/docker-desktop)
- **kubectl** (https://kubernetes.io/docs/tasks/tools/)
- **kind** (https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- **curl** and **jq** (for testing)

### Quick Installation

**macOS (Homebrew):**
```bash
brew install docker kubectl kind jq
```

**Linux:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

**Windows (Chocolatey):**
```powershell
choco install docker-desktop kubernetes-cli kind jq
```

## 🚀 Quick Start

### 1. One-Command Setup

```bash
cd local-dev/scripts
./setup.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Start MinIO, Prometheus, and Grafana with Docker Compose
- ✅ Build Docker images for edge-simulator and ingestion-service
- ✅ Create a 3-node kind cluster
- ✅ Load images into the cluster
- ✅ Deploy all Kubernetes manifests
- ✅ Wait for everything to be ready

Setup takes approximately **3-5 minutes**.

### 2. Verify Installation

```bash
./demo.sh
```

This shows:
- All service URLs
- Kubernetes pod status
- Recent logs
- Useful demo commands

## 🌐 Access the Platform

Once setup is complete, access the following services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Ingestion Service** | http://localhost:30080 | - |
| **Prometheus** | http://localhost:30090 | - |
| **Grafana** | http://localhost:30030 | admin / admin |
| **MinIO Console** | http://localhost:9001 | minioadmin / minioadmin |
| **MinIO API** | http://localhost:9000 | - |

## 🎬 Demo Flow for Screen Recording

### Step 1: Show Architecture Overview
Start by explaining the architecture while showing the terminal:

```bash
kubectl get nodes  # Show 3-node cluster
kubectl get pods   # Show all running pods
kubectl get svc    # Show services
```

### Step 2: Demonstrate Data Flow

**Terminal 1 - Watch Logs:**
```bash
kubectl logs -f deployment/edge-simulator
```

**Terminal 2 - Watch Ingestion:**
```bash
kubectl logs -f deployment/ingestion-service
```

**Terminal 3 - Monitor Pods:**
```bash
watch kubectl get pods
```

### Step 3: Show Real-Time Metrics

**Open Prometheus:** http://localhost:30090

Example queries to demo:
```promql
# Request rate
rate(telemetry_requests_total[1m])

# Success rate
sum(rate(telemetry_requests_total{status="success"}[5m])) / sum(rate(telemetry_requests_total[5m]))

# Request duration (p95)
histogram_quantile(0.95, rate(telemetry_processing_duration_seconds_bucket[5m]))
```

### Step 4: Show Grafana Dashboards

**Open Grafana:** http://localhost:30030
- Login with `admin` / `admin`
- Navigate to dashboards (if provisioned)
- Show real-time metrics visualization

### Step 5: Demonstrate Kubernetes Features

**Horizontal Pod Autoscaling:**
```bash
kubectl get hpa
kubectl describe hpa ingestion-service-hpa
```

**Pod Disruption Budget:**
```bash
kubectl get pdb
kubectl describe pdb ingestion-service-pdb
```

**Scale Up Demo:**
```bash
# Scale up edge simulators to increase load
kubectl scale deployment edge-simulator --replicas=3

# Watch HPA respond
watch kubectl get hpa
```

### Step 6: Show Data in MinIO

**Browser:** http://localhost:9001
- Login with `minioadmin` / `minioadmin`
- Browse `f1-telemetry-raw` bucket
- Show telemetry data structure

**CLI:**
```bash
docker exec f1-minio mc ls myminio/f1-telemetry-raw/raw-telemetry/ --recursive
```

### Step 7: Manual Testing

Test the ingestion endpoint:
```bash
./test-ingestion.sh
```

Or manually:
```bash
curl http://localhost:30080/health
curl http://localhost:30080/metrics
```

## 📊 Monitoring & Observability

### View Logs

```bash
# All ingestion service logs
kubectl logs -l app=ingestion-service

# Follow logs in real-time
kubectl logs -f deployment/ingestion-service

# Edge simulator logs
kubectl logs -f deployment/edge-simulator

# View logs from all pods
kubectl logs -l app=ingestion-service --all-containers=true
```

### Check Metrics

```bash
# Ingestion service metrics
curl http://localhost:30080/metrics

# Kubernetes metrics
kubectl top nodes
kubectl top pods
```

### Monitor HPA Behavior

```bash
# Watch HPA in real-time
watch kubectl get hpa

# Detailed HPA status
kubectl describe hpa ingestion-service-hpa
```

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs <pod-name>
```

### MinIO Connection Issues

```bash
# Check if MinIO is running
docker ps | grep minio

# Check MinIO logs
docker logs f1-minio

# Test MinIO connectivity from host
curl http://localhost:9000/minio/health/live
```

### Metrics Not Showing in Prometheus

```bash
# Check Prometheus targets
# Open: http://localhost:30090/targets

# Verify service discovery
kubectl get pods -o wide
kubectl get endpoints
```

### Image Pull Errors

```bash
# Reload images into kind
kind load docker-image f1-ingestion-service:latest --name f1-telemetry
kind load docker-image f1-edge-simulator:latest --name f1-telemetry

# Restart deployments
kubectl rollout restart deployment/ingestion-service
kubectl rollout restart deployment/edge-simulator
```

## 🎯 Advanced Demo Scenarios

### Simulate Network Latency

Edit edge-simulator deployment:
```bash
kubectl set env deployment/edge-simulator SIMULATE_LATENCY=true COLLECTION_INTERVAL=10
```

### Simulate Packet Loss

```bash
kubectl set env deployment/edge-simulator SIMULATE_PACKET_LOSS=true PACKET_LOSS_RATE=0.1
```

### Race Weekend Mode

Increase replicas and disable auto-scaling:
```bash
# Scale up
kubectl scale deployment ingestion-service --replicas=5

# Fix HPA temporarily
kubectl patch hpa ingestion-service-hpa -p '{"spec":{"minReplicas":5,"maxReplicas":5}}'

# Restore auto-scaling after demo
kubectl patch hpa ingestion-service-hpa -p '{"spec":{"minReplicas":2,"maxReplicas":5}}'
```

### Chaos Engineering

Test resilience by deleting pods:
```bash
# Delete a pod and watch it recreate
kubectl delete pod -l app=ingestion-service --force

# Watch recovery
watch kubectl get pods

# Verify PDB prevents full disruption
kubectl drain <node-name> --ignore-daemonsets
```

## 📸 Screenshot Recommendations

For your portfolio/demo, capture:

1. **Terminal with setup script running** - Shows technical setup
2. **kubectl get pods output** - Shows Kubernetes orchestration
3. **Prometheus with queries** - Shows monitoring capabilities
4. **Grafana dashboard** - Shows data visualization
5. **MinIO console with data** - Shows data persistence
6. **HPA in action** - Shows auto-scaling
7. **Logs showing data flow** - Shows real-time processing

## 🧹 Cleanup

When done with the demo:

```bash
./teardown.sh
```

This will:
- Delete the kind cluster
- Stop Docker Compose services
- Clean up resources

Note: MinIO data in `local-dev/minio-data/` persists. Delete manually if needed:
```bash
rm -rf local-dev/minio-data/*
```

## 💡 Tips for Recruitment Demo

### Talking Points

1. **Hybrid Architecture**: Explain edge-to-cloud pattern (simulated locally)
2. **Cloud-Native**: Emphasize Kubernetes, containers, observability
3. **Production-Ready**: HPA, PDB, health checks, metrics
4. **Infrastructure as Code**: Show Terraform folder (AWS deployment ready)
5. **CI/CD**: Show GitHub Actions workflows (automated deployment)
6. **Monitoring**: Prometheus metrics, Grafana dashboards
7. **Data Pipeline**: S3 → Glue → Athena (show architecture even if using MinIO locally)
8. **Race Weekend Mindset**: Explain infrastructure freeze, scaling strategy

### Demo Script (5-10 minutes)

1. **Intro** (1 min): Explain project goal and Toyota Gazoo Racing context
2. **Architecture** (2 min): Show diagram, explain components
3. **Live Demo** (5 min):
   - Show running pods
   - Show metrics in Prometheus
   - Show data in MinIO
   - Demonstrate HPA
   - Show logs
4. **Infrastructure** (2 min): Briefly show Terraform code, explain AWS setup
5. **Wrap-up** (1 min): Highlight how this demonstrates required skills from job description

### Key Skills to Highlight

- ✅ **AWS**: Show Terraform modules (EKS, VPC, S3, IAM)
- ✅ **Kubernetes**: Running locally but production-ready manifests
- ✅ **Terraform**: Infrastructure as Code, modules, environments
- ✅ **Docker**: Containerization, multi-stage builds
- ✅ **CI/CD**: GitHub Actions workflows
- ✅ **Python**: Edge simulator and ingestion service
- ✅ **Observability**: Prometheus, Grafana, metrics
- ✅ **Data Engineering**: S3 partitioning, Athena queries
- ✅ **Motorsport Understanding**: Race weekend operations, edge computing

## 📚 Further Reading

- [PROJECT.md](../OBJECTIVE.MD) - Original project objectives
- [terraform/](../terraform/) - AWS infrastructure code
- [k8s/](../k8s/) - Production Kubernetes manifests
- [.github/workflows/](../.github/workflows/) - CI/CD pipelines

## 🆘 Need Help?

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Port already in use | Change ports in docker-compose.yml |
| Docker daemon not running | Start Docker Desktop |
| kubectl not configured | kind creates kubeconfig automatically |
| Images not found | Re-run setup.sh to build and load images |
| HPA not working | Ensure metrics-server is running |

## 🎉 Success Checklist

Before your demo, verify:

- [ ] All pods are Running (`kubectl get pods`)
- [ ] Services are accessible (check all URLs)
- [ ] Logs show data flowing
- [ ] Metrics visible in Prometheus
- [ ] Grafana dashboards loading
- [ ] MinIO has telemetry data
- [ ] HPA shows current metrics
- [ ] You can explain each component

Good luck with your demo! 🚀🏎️
