# 🎬 Demo Quick Reference Guide

## Pre-Demo Checklist (5 minutes before)

```bash
# 1. Start everything
cd local-dev/scripts
./setup.sh

# 2. Wait for all pods to be ready
kubectl get pods --watch

# 3. Verify all services are accessible
curl http://localhost:30080/health  # Should return 200
curl http://localhost:30090/-/healthy  # Prometheus
curl http://localhost:9001  # MinIO console

# 4. Open browser tabs
# - http://localhost:30030 (Grafana - login: admin/admin)
# - http://localhost:30090 (Prometheus)
# - http://localhost:9001 (MinIO - login: minioadmin/minioadmin)

# 5. Prepare terminals
# Terminal 1: kubectl logs -f deployment/ingestion-service
# Terminal 2: kubectl logs -f deployment/edge-simulator
# Terminal 3: watch kubectl get pods
```

## Demo Script (10 minutes)

### Part 1: Introduction (2 minutes)

**Say:**
> "I built a motorsport-inspired telemetry platform that demonstrates cloud-native architecture for race operations. This simulates edge devices at the track sending data to cloud infrastructure - similar to what Toyota Gazoo Racing uses during race weekends."

**Show:**
- Architecture diagram (draw or use OBJECTIVE.MD)
- Quick overview of folder structure

### Part 2: Local Demo (5 minutes)

**Terminal Commands:**
```bash
# Show the cluster
kubectl get nodes
# Say: "3-node Kubernetes cluster running locally with kind"

# Show all components
kubectl get pods -o wide
# Say: "Ingestion service with 2 replicas, edge simulator, Prometheus, Grafana"

# Show services
kubectl get svc
# Say: "NodePort services expose Prometheus and Grafana locally"

# Show auto-scaling
kubectl get hpa
# Say: "HPA configured for 2-5 replicas based on CPU and memory"

# Show pod disruption budget
kubectl get pdb
# Say: "PDB ensures at least 1 pod is always available - critical for race weekends"
```

**Show Logs:**
```bash
# Terminal 1 - Edge Simulator
kubectl logs -f deployment/edge-simulator --tail=20
# Say: "Edge device collecting F1 data from Ergast API and sending to cloud"

# Terminal 2 - Ingestion Service
kubectl logs -f deployment/ingestion-service --tail=20
# Say: "FastAPI service receiving telemetry, storing in MinIO (S3-compatible)"
```

**Show Metrics (Prometheus):**
- Open http://localhost:30090
- Execute query: `rate(telemetry_requests_total[1m])`
- Say: "Real-time request rate - this would spike during quali and race"
- Execute: `histogram_quantile(0.95, rate(telemetry_processing_duration_seconds_bucket[5m]))`
- Say: "p95 latency tracking - critical for race weekend SLAs"

**Show Data (MinIO):**
- Open http://localhost:9001
- Browse: `f1-telemetry-raw` bucket
- Say: "Data partitioned by year/month/day/type for efficient Athena queries"

**Demonstrate Scaling:**
```bash
# Scale up edge simulators to increase load
kubectl scale deployment edge-simulator --replicas=3

# Watch HPA respond
kubectl get hpa --watch
# Say: "Watch auto-scaling respond to increased load"

# Scale back down
kubectl scale deployment edge-simulator --replicas=1
```

### Part 3: Code Walkthrough (2 minutes)

**Terraform:**
```bash
tree terraform/modules -L 2
# Say: "Modular Terraform for AWS - VPC, EKS, S3, IAM with IRSA"
cat terraform/modules/eks/main.tf | head -30
# Say: "EKS cluster with OIDC provider for secure IAM roles"
```

**Kubernetes:**
```bash
cat k8s/ingestion-service/hpa.yaml
# Say: "HPA with conservative scale-down for stability"
cat k8s/ingestion-service/pdb.yaml
# Say: "PDB ensures availability during node maintenance"
```

**Python Services:**
```bash
cat ingestion-service/main.py | head -50
# Say: "FastAPI with Prometheus metrics, health checks, S3/MinIO compatible"
```

### Part 4: Production Readiness (1 minute)

**Show CI/CD:**
```bash
ls -la .github/workflows/
# Say: "Three automated pipelines:"
# - terraform.yml: Infrastructure deployment with plan previews
# - docker-build.yml: Container builds with security scanning
# - kubernetes-deploy.yml: GitOps-style deployments to EKS
```

**Show Analytics:**
```bash
cat analytics/athena/queries/lap_times_analysis.sql
# Say: "SQL queries for post-race analysis using Athena"
cat analytics/glue/crawler.json
# Say: "Automated schema discovery with Glue crawler"
```

## Key Talking Points

### Technical Excellence
- ✅ "Uses IRSA - no static credentials in pods or code"
- ✅ "HPA with both CPU and memory metrics, aggressive scale-up, conservative scale-down"
- ✅ "S3 data partitioned for cost-effective Athena queries"
- ✅ "Prometheus metrics exported from application for observability"
- ✅ "All infrastructure defined as code with Terraform modules"

### Motorsport Context
- ✅ "PDB ensures minimum pods during race - can't afford downtime during quali"
- ✅ "Edge simulator includes network latency and packet loss - realistic trackside conditions"
- ✅ "Race weekend mode: scale up, freeze infrastructure, monitor closely"
- ✅ "Data retention: hot data in S3 Standard, lifecycle to Glacier after 90 days"
- ✅ "Separate dev/prod environments with different sizing"

### Job Requirements Match
- ✅ "EKS, VPC, S3, IAM, Athena, Glue - all the AWS services from the JD"
- ✅ "Terraform with modules for reusability across environments"
- ✅ "CI/CD with GitHub Actions, can be adapted to Azure DevOps"
- ✅ "Python for both edge and cloud services"
- ✅ "Containerized workloads with proper resource management"

## Demo Commands Cheat Sheet

```bash
# Setup
./local-dev/scripts/setup.sh

# Status check
./local-dev/scripts/demo.sh

# Test endpoint
curl http://localhost:30080/health
./local-dev/scripts/test-ingestion.sh

# Watch logs
kubectl logs -f deployment/ingestion-service
kubectl logs -f deployment/edge-simulator

# Monitor
watch kubectl get pods
watch kubectl get hpa
kubectl top pods

# Scale demo
kubectl scale deployment edge-simulator --replicas=3
kubectl scale deployment ingestion-service --replicas=5

# Check data
docker exec f1-minio mc ls myminio/f1-telemetry-raw/raw-telemetry/ --recursive

# Cleanup
./local-dev/scripts/teardown.sh
```

## Prometheus Queries for Demo

```promql
# Request rate
rate(telemetry_requests_total[1m])

# Success rate (%)
sum(rate(telemetry_requests_total{status="success"}[5m])) / sum(rate(telemetry_requests_total[5m])) * 100

# p95 latency
histogram_quantile(0.95, rate(telemetry_processing_duration_seconds_bucket[5m]))

# Requests by data type
sum(rate(telemetry_requests_total[5m])) by (data_type)

# S3 upload duration
histogram_quantile(0.95, rate(s3_upload_duration_seconds_bucket[5m]))
```

## Common Issues During Demo

| Issue | Quick Fix |
|-------|-----------|
| Pods in Pending | `kubectl describe pod <name>` - check events |
| Service unreachable | `kubectl get svc` - verify NodePort |
| No data in MinIO | Check edge-simulator logs for errors |
| Metrics not showing | Verify Prometheus scrape config |
| HPA shows `<unknown>` | Wait for metrics-server to collect data (~1 min) |

## Post-Demo Follow-Up

**Questions to Prepare For:**

1. **"How would you deploy this to production AWS?"**
   - Show terraform apply workflow
   - Mention state management in S3
   - Discuss blue-green deployments

2. **"How do you handle secrets?"**
   - IRSA for AWS credentials
   - Kubernetes secrets for MinIO locally
   - AWS Secrets Manager for production

3. **"What about disaster recovery?"**
   - S3 versioning and replication
   - EKS snapshots
   - Infrastructure as Code for rebuild

4. **"How would you monitor during a race?"**
   - Grafana race weekend dashboard
   - Alert thresholds for error rates
   - Escalation to on-call

5. **"What would you improve?"**
   - Add service mesh (Istio) for advanced traffic management
   - Implement OpenTelemetry for distributed tracing
   - Add automated integration tests
   - Multi-region deployment for redundancy

## Recording Tips

### Screen Layout
- **Primary**: Terminal with clear, large font
- **Secondary**: Browser with Grafana/Prometheus
- **Picture-in-Picture**: Your face (optional)

### Audio
- Test microphone before recording
- Speak clearly and at moderate pace
- Pause between sections

### Video
- Use OBS Studio or similar for high quality
- 1080p minimum resolution
- Show mouse cursor for clarity
- Use zoom/highlight for important code sections

### Duration
- Aim for 8-12 minutes total
- Can be edited to 5 minutes highlight reel

## Success Criteria

✅ All pods running and healthy
✅ Data flowing from simulator to MinIO
✅ Metrics visible in Prometheus
✅ Grafana accessible
✅ HPA showing current metrics
✅ Can scale up/down smoothly
✅ Logs show successful operations
✅ Can explain each component confidently

---

**Remember:** You understand race operations, not just Kubernetes!

Good luck! 🏎️💨
