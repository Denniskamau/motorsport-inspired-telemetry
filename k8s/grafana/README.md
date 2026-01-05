# Grafana Dashboards

Grafana dashboards for monitoring F1 telemetry platform.

## Dashboards

### 1. Telemetry Overview
**File**: `telemetry-overview.json`

General monitoring dashboard with:
- Success rate statistics
- Request throughput by data type
- Processing duration (p50, p95)
- S3 upload performance
- Error rates with alerts
- Pod resource usage (CPU, memory)

Use this for:
- Day-to-day monitoring
- Performance analysis
- Capacity planning

### 2. Race Weekend Mode
**File**: `race-weekend-mode.json`

High-frequency monitoring for race weekends:
- Real-time ingestion status (5s refresh)
- Active pods count
- Live throughput graphs
- Latency percentiles (p50, p95, p99)
- Error spike detection
- Edge device reporting status
- S3 upload performance

Use this for:
- Race weekend operations
- Real-time incident response
- SLA monitoring

## Setup

### Prerequisites

1. Prometheus installed in cluster
2. Metrics Server installed
3. Applications exposing `/metrics` endpoint

### Install Prometheus

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace default \
  --set alertmanager.enabled=false \
  --set pushgateway.enabled=false \
  --set server.service.type=ClusterIP
```

### Deploy Grafana

```bash
# Create ConfigMap for dashboards
kubectl create configmap grafana-dashboards \
  --from-file=k8s/grafana/dashboards/ \
  --namespace=default

# Deploy Grafana
kubectl apply -f k8s/grafana/deployment.yaml

# Get Grafana LoadBalancer URL
kubectl get svc grafana
```

### Access Grafana

```bash
# Get external IP/hostname
kubectl get svc grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Default credentials:
# Username: admin
# Password: admin (change on first login)
```

### Import Dashboards

Dashboards are automatically provisioned via ConfigMap. To manually import:

1. Open Grafana UI
2. Go to Dashboards → Import
3. Upload JSON files from `dashboards/` directory
4. Select Prometheus datasource

## Metrics Reference

### Application Metrics

Exposed by ingestion service at `/metrics`:

```
# Request metrics
telemetry_requests_total{data_type, status}
telemetry_processing_duration_seconds{data_type}
s3_upload_duration_seconds{bucket}

# Labels:
# - data_type: lap_times, pit_stops, race_results, qualifying
# - status: success, failed, error
# - bucket: S3 bucket name
```

### Kubernetes Metrics

From metrics-server and kube-state-metrics:

```
# Pod metrics
container_cpu_usage_seconds_total{pod}
container_memory_working_set_bytes{pod}
kube_pod_status_phase{pod, phase}

# Node metrics
node_cpu_utilization
node_memory_utilization
```

## Alerts

### High Error Rate
**Trigger**: Error rate > 10 requests/min for 5 minutes
**Action**: Check application logs and S3 permissions

### High Latency
**Trigger**: p95 latency > 500ms for 1 minute
**Action**: Scale up pods or check S3 performance

### Error Spike
**Trigger**: > 5 errors in 1 minute
**Action**: Immediate investigation required

## Race Weekend Monitoring Workflow

### Pre-Race Setup

```bash
# 1. Verify Prometheus is collecting metrics
kubectl port-forward svc/prometheus-server 9090:80
# Open http://localhost:9090 and check targets

# 2. Verify ingestion service metrics
kubectl port-forward svc/ingestion-service 8000:80
curl http://localhost:8000/metrics

# 3. Open Grafana Race Weekend Dashboard
# Switch to Race Weekend Mode dashboard
```

### During Race

Monitor these panels:
- **LIVE: Ingestion Status**: Should show steady requests/sec
- **Active Pods**: Should match expected count
- **System Health**: Should stay > 99%
- **Real-Time Throughput**: Watch for drops
- **Latency**: Watch for spikes
- **Error Count**: Should be zero or near-zero

### Post-Race Analysis

Switch to Telemetry Overview dashboard:
- Review total requests
- Analyze request distribution by type
- Check resource usage trends
- Identify any performance bottlenecks

## Customization

### Add New Panel

1. Edit dashboard JSON
2. Add new panel in `panels` array
3. Update ConfigMap:

```bash
kubectl create configmap grafana-dashboards \
  --from-file=k8s/grafana/dashboards/ \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -
```

4. Restart Grafana:

```bash
kubectl rollout restart deployment/grafana
```

### Add Prometheus Annotations

Mark race events on graphs:

```bash
# Create annotation
curl -X POST http://grafana-url/api/annotations \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Race Start",
    "tags": ["race", "start"],
    "time": '$(date +%s000)'
  }'
```

## Troubleshooting

### No Data in Graphs

```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus-server 9090:80
# Visit http://localhost:9090/targets

# Check if ingestion service is exposing metrics
kubectl port-forward svc/ingestion-service 8000:80
curl http://localhost:8000/metrics

# Check Grafana datasource
# Grafana → Configuration → Data Sources → Prometheus → Test
```

### Dashboards Not Loading

```bash
# Check ConfigMap
kubectl get configmap grafana-dashboards -o yaml

# Check Grafana logs
kubectl logs deployment/grafana

# Manually provision dashboards
kubectl exec -it deployment/grafana -- ls /var/lib/grafana/dashboards
```

### High Memory Usage

```bash
# Increase Grafana resources
kubectl patch deployment grafana -p '{"spec":{"template":{"spec":{"containers":[{"name":"grafana","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
```

## Future Enhancements

1. **CloudWatch Integration**: Add CloudWatch datasource for AWS metrics
2. **Athena Query Results**: Display analytics query results
3. **Alertmanager**: Configure email/Slack notifications
4. **Custom Metrics**: Add business metrics (e.g., lap count, driver stats)
5. **SLO Dashboard**: Track Service Level Objectives
