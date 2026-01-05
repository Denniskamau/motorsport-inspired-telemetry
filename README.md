# 🏎️ F1 Telemetry Platform - Motorsport-Inspired Cloud Infrastructure

A production-ready, cloud-native telemetry platform demonstrating hybrid edge-to-cloud architecture inspired by Formula 1 racing operations. Built to showcase skills for **AWS Cloud Engineering roles in motorsport**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)]()
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)]()
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)]()

---

## 🎯 Project Overview

This project simulates a real-world F1 telemetry system that collects data from trackside edge devices and processes it in the cloud. It demonstrates:

- **Edge-to-Cloud Architecture**: Simulates trackside data collection and cloud ingestion
- **Production Kubernetes**: EKS deployment with HPA, PDB, and proper resource management
- **Infrastructure as Code**: Complete Terraform modules for AWS infrastructure
- **Cloud-Native Observability**: Prometheus metrics and Grafana dashboards
- **Data Pipeline**: S3 → Glue → Athena for analytics
- **CI/CD**: Automated deployment with GitHub Actions
- **Race Weekend Operations**: Infrastructure freeze procedures and scaling strategies

### Why This Project?

Built specifically for **Toyota Gazoo Racing Europe - AWS Cloud Engineer** role, this project demonstrates:

✅ Hybrid thinking (edge → cloud)
✅ Race-weekend reliability mindset
✅ Data latency awareness
✅ Kubernetes mastery (EKS)
✅ Infrastructure as Code (Terraform)
✅ Observability (Prometheus/Grafana)
✅ Data engineering (S3, Glue, Athena)

## 🏗️ Architecture

```
┌─────────────────┐
│  F1 Data Source │ (Ergast API)
│  (Live Races)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Edge Simulator  │ (Docker Container)
│  - Collects     │
│  - Enriches     │
│  - Transmits    │
└────────┬────────┘
         │ HTTP/TLS
         ▼
┌─────────────────┐
│  AWS Ingestion  │ (ALB → EKS)
│   API Gateway   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  EKS Cluster    │
│  - FastAPI      │
│  - Auto-scaling │
│  - Observability│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  S3 Storage     │
│  - Raw data     │
│  - Partitioned  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Glue Crawler   │
│  Schema Discovery
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Athena         │
│  SQL Analytics  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Grafana        │
│  Dashboards     │
└─────────────────┘
```

## 🚀 Quick Start - Local Demo

Perfect for portfolio demonstrations and cost-free testing!

### Prerequisites
- Docker Desktop
- kubectl
- kind
- curl, jq

### One-Command Setup

```bash
cd local-dev/scripts
./setup.sh
```

**That's it!** In 3-5 minutes you'll have:
- ✅ 3-node Kubernetes cluster (kind)
- ✅ MinIO (S3-compatible storage)
- ✅ Prometheus + Grafana
- ✅ Ingestion service (2 replicas)
- ✅ Edge simulator
- ✅ All monitoring and auto-scaling configured

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Ingestion API | http://localhost:30080 | - |
| Prometheus | http://localhost:30090 | - |
| Grafana | http://localhost:30030 | admin / admin |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin |

### Run Demo Script

```bash
./demo.sh  # Shows all components and status
```

📖 **Detailed instructions**: [local-dev/README.md](local-dev/README.md)

## 🏠 Raspberry Pi Home Lab (Recommended for Job Applications!)

Deploy this platform on a Raspberry Pi with **24/7 public access** via Cloudflare Tunnel. Perfect for sharing a **live demo** in your job application!

### Why Raspberry Pi?
- ✅ **Live 24/7 demo** - Share URL with recruiters
- ✅ **Production-like** - Real hardware, real persistence
- ✅ **Home lab experience** - Highly valued on CV
- ✅ **Cost-effective** - $5/month power vs $140/month AWS
- ✅ **Secure public access** - Cloudflare Tunnel (no open ports)
- ✅ **Impressive** - Shows initiative and real infrastructure skills

### Hardware Requirements
- Raspberry Pi 4 (4GB+ RAM, 8GB recommended)
- External SSD (256GB+, USB 3.0)
- Total cost: ~$150 (one-time)

### Quick Setup
```bash
# SSH to your Raspberry Pi
ssh pi@raspberrypi.local

# Clone and run automated setup
git clone https://github.com/yourusername/motorsport-inspired-telemetry.git
cd motorsport-inspired-telemetry/raspberry-pi
./setup-pi.sh
```

This deploys:
- ✅ k3s Kubernetes (lightweight, ARM-native)
- ✅ All services (MinIO, Prometheus, Grafana, Telemetry)
- ✅ Persistent storage on external SSD
- ✅ Ready for Cloudflare Tunnel

### Public Access (Cloudflare Tunnel)
```bash
# Install and configure cloudflared
cloudflared tunnel create f1-telemetry
cloudflared tunnel route dns f1-telemetry f1-telemetry.yourdomain.com
sudo cloudflared service install
sudo systemctl start cloudflared
```

**Result**: Your dashboard is now publicly accessible at:
- **Grafana**: https://f1-telemetry.yourdomain.com
- **Share this URL** in your job application!

📖 **Complete guide**: [raspberry-pi/RASPBERRY-PI-DEPLOYMENT.md](raspberry-pi/RASPBERRY-PI-DEPLOYMENT.md)
📊 **Comparison**: [raspberry-pi/COMPARISON.md](raspberry-pi/COMPARISON.md)

### Cost Comparison

| Deployment | Initial Cost | Monthly Cost | Public Access | Uptime |
|------------|--------------|--------------|---------------|--------|
| **Raspberry Pi** | $150 | $5 | ✅ (Cloudflare) | 24/7 |
| **AWS Production** | $0 | $140 | ✅ (ALB) | 24/7 |
| **Local (kind)** | $0 | $0 | ❌ | Intermittent |

**ROI**: Pi pays for itself in 2 months vs AWS!

## ☁️ AWS Production Deployment

### Infrastructure Components

**Networking:**
- VPC with public/private subnets across 3 AZs
- NAT Gateways for outbound traffic
- VPC Flow Logs
- Security Groups with least-privilege

**Compute:**
- EKS cluster with managed node groups
- Auto-scaling (1-5 nodes)
- IRSA (IAM Roles for Service Accounts)
- No static credentials

**Storage:**
- S3 buckets (raw, processed, athena-results)
- Intelligent tiering and lifecycle policies
- Encryption at rest
- Versioning enabled

**Data Analytics:**
- Glue Data Catalog
- Glue Crawler (scheduled)
- Athena for SQL queries
- Partitioned data (year/month/day/type)

**Observability:**
- CloudWatch Logs
- Prometheus in-cluster
- Grafana dashboards
- Custom metrics

### Deploy to AWS

```bash
# 1. Configure AWS credentials
export AWS_PROFILE=your-profile

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Plan deployment
terraform plan -var-file=environments/dev/terraform.tfvars

# 4. Deploy infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars

# 5. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name f1-telemetry-dev

# 6. Deploy applications
kubectl apply -f k8s/ingestion-service/
kubectl apply -f k8s/edge-simulator/
```

📖 **Detailed instructions**: [terraform/README.md](terraform/README.md)

## 📁 Project Structure

```
.
├── edge-simulator/           # Edge device simulation
│   ├── main.py              # Python telemetry collector
│   ├── Dockerfile
│   └── requirements.txt
│
├── ingestion-service/        # FastAPI ingestion service
│   ├── main.py              # API endpoints
│   ├── Dockerfile
│   └── requirements.txt
│
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # Root module
│   ├── modules/             # Reusable modules
│   │   ├── vpc/            # Networking
│   │   ├── eks/            # Kubernetes
│   │   ├── s3/             # Storage
│   │   └── iam/            # Access control
│   └── environments/        # Dev/Prod configs
│
├── k8s/                      # Kubernetes manifests (AWS)
│   ├── ingestion-service/   # Deployment, HPA, PDB
│   ├── edge-simulator/
│   └── grafana/            # Monitoring dashboards
│
├── local-dev/                # Local development setup
│   ├── docker-compose.yml   # MinIO, Prometheus, Grafana
│   ├── k8s/                # Local K8s manifests
│   └── scripts/            # Setup automation
│
├── analytics/                # Data analytics
│   ├── glue/               # Crawler configuration
│   └── athena/             # SQL queries
│
├── .github/
│   └── workflows/          # CI/CD pipelines
│       ├── terraform.yml
│       ├── docker-build.yml
│       └── kubernetes-deploy.yml
│
└── docs/                    # Additional documentation
```

## 🔑 Key Features

### 1. Production-Ready Kubernetes

- **Horizontal Pod Autoscaler**: CPU/memory-based scaling
- **Pod Disruption Budgets**: Ensures availability during disruptions
- **Resource Limits**: Proper CPU/memory requests and limits
- **Health Checks**: Liveness and readiness probes
- **Rolling Updates**: Zero-downtime deployments

### 2. Security Best Practices

- **IRSA**: No static AWS credentials in pods
- **Secret Management**: Kubernetes secrets for sensitive data
- **Network Policies**: (Optional) Pod-to-pod communication control
- **Encryption**: At-rest (S3) and in-transit (TLS)
- **IAM Boundaries**: Least-privilege access

### 3. Observability

- **Metrics**: Prometheus with custom application metrics
- **Dashboards**: Grafana with pre-configured dashboards
- **Logs**: CloudWatch Logs integration
- **Tracing**: (Future) OpenTelemetry integration
- **Alerts**: (Future) PagerDuty/Slack integration

### 4. Data Engineering

- **Partitioned Storage**: Efficient S3 layout for Athena
- **Schema Evolution**: Glue handles schema changes
- **Query Optimization**: Partition projection
- **Cost Efficiency**: S3 lifecycle policies

### 5. CI/CD Pipeline

- **Terraform**: Automated infrastructure deployment
- **Docker**: Multi-stage builds, security scanning
- **Kubernetes**: GitOps-style deployments
- **Testing**: (Future) Integration and E2E tests

## 🎬 Demo for Recruitment

### Screen Recording Tips

1. **Start with Overview** (1-2 min)
   - Explain the project goal
   - Show architecture diagram
   - Relate to real F1 operations

2. **Local Demo** (5-7 min)
   - Run `./setup.sh` (time-lapse if needed)
   - Show running pods: `kubectl get pods`
   - Demonstrate data flow with logs
   - Show Prometheus metrics
   - Navigate Grafana dashboard
   - Show data in MinIO
   - Demonstrate auto-scaling: `kubectl get hpa`

3. **Code Walkthrough** (3-5 min)
   - Terraform modules (VPC, EKS, IAM)
   - Kubernetes manifests (HPA, PDB)
   - Python services (ingestion, simulator)
   - CI/CD workflows

4. **Race Weekend Operations** (2-3 min)
   - Explain infrastructure freeze
   - Show scaling procedures
   - Discuss monitoring strategy
   - Explain failure scenarios and mitigation

### Talking Points

**Technical Skills:**
- "This demonstrates hybrid edge-to-cloud architecture similar to what you'd use during race weekends"
- "The infrastructure is defined as code using Terraform, with separate modules for reusability"
- "I'm using IRSA for security - no static credentials stored anywhere"
- "The HPA and PDB ensure high availability even during node failures"
- "Data is partitioned in S3 for efficient Athena queries"

**Motorsport Context:**
- "During a race weekend, you'd scale up before qualifying and maintain capacity"
- "The PDB ensures you always have minimum pods running - critical for live events"
- "Metrics are exported to Prometheus for real-time monitoring during races"
- "The edge simulator represents trackside systems with realistic network conditions"

## 📊 Performance & Scale

### Current Configuration (Local)

- **Cluster**: 3 nodes (1 control-plane, 2 workers)
- **Ingestion Service**: 2-5 replicas (auto-scaling)
- **Resources**: ~1 CPU, ~2GB RAM total
- **Data Rate**: Simulated F1 API calls every 30s

### Production Configuration (AWS)

- **Cluster**: 1-5 t3.large nodes (auto-scaling)
- **Ingestion Service**: 2-10 replicas (HPA)
- **Expected Load**: 100+ requests/second
- **Storage**: S3 with lifecycle to Glacier after 90 days
- **Cost**: ~$200-400/month (estimate)

## 🧪 Testing

### Local Testing

```bash
# Test health endpoint
curl http://localhost:30080/health

# Test metrics
curl http://localhost:30080/metrics

# Manual telemetry test
./local-dev/scripts/test-ingestion.sh

# View data in MinIO
docker exec f1-minio mc ls myminio/f1-telemetry-raw/raw-telemetry/ --recursive
```

### Load Testing

```bash
# Scale up edge simulators
kubectl scale deployment edge-simulator --replicas=5

# Watch HPA respond
watch kubectl get hpa

# Monitor metrics
kubectl top pods
```

## 📚 Documentation

- [Local Development Guide](local-dev/README.md) - Run locally with kind
- [Terraform Guide](terraform/README.md) - AWS infrastructure deployment
- [Kubernetes Guide](k8s/README.md) - K8s manifests and operations
- [Analytics Guide](analytics/README.md) - Glue and Athena setup
- [CI/CD Guide](.github/workflows/README.md) - GitHub Actions pipelines

## 🎓 Learning Resources

This project demonstrates concepts from:

- AWS Well-Architected Framework
- Kubernetes Best Practices (Google/CNCF)
- 12-Factor App Methodology
- GitOps Principles
- Site Reliability Engineering (SRE)

## 🤝 Contributing

This is a portfolio project, but suggestions are welcome! Feel free to:

- Open issues for bugs or improvements
- Submit PRs for enhancements
- Share your own motorsport-inspired projects

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- **Ergast F1 API** - Free F1 data source
- **Toyota Gazoo Racing Europe** - Inspiration for the project
- **Cloud Native Community** - Best practices and tooling

## 📧 Contact

**Dennis** - [Your LinkedIn] | [Your Email]

Portfolio: [Your Website]
GitHub: [@YourGitHub](https://github.com/your-username)

---

## 🎯 Skills Demonstrated

This project showcases the following skills (from the Toyota Gazoo Racing job description):

### Required Skills ✅

- [x] **AWS Services**: EKS, ECS, VPC, EC2, IAM, CloudTrail, Athena, RDS, ECR, S3
- [x] **Infrastructure as Code**: Terraform with modules and environments
- [x] **Kubernetes**: EKS, deployments, HPA, PDB, IRSA, service mesh ready
- [x] **Docker**: Containerization, multi-stage builds, optimization
- [x] **CI/CD**: GitHub Actions, automated deployments, GitOps principles
- [x] **DevOps Practices**: Observability, monitoring, automation

### Bonus Skills ✅

- [x] **Python**: FastAPI service, edge simulator with retry logic
- [x] **Data Engineering**: S3 partitioning, Glue, Athena
- [x] **Networking**: VPC design, security groups, load balancing
- [x] **Observability**: Prometheus metrics, Grafana dashboards
- [x] **Race Weekend Operations**: Demonstrated understanding of reliability requirements

---

**Built with ❤️ for motorsport and cloud engineering**

🏎️💨 *"I understand race operations, not just Kubernetes."*
