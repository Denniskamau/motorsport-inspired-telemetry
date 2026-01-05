# 📊 Visual Dashboards - F1 Telemetry Platform

## 🎯 Quick Access URLs

All services are running and accessible via NodePort on your local kind cluster:

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| **Grafana Dashboards** | http://localhost:30030 | admin / admin | Main visualization UI |
| **Prometheus Metrics** | http://localhost:30090 | None | Raw metrics & queries |
| **MinIO Console** | http://localhost:30901 | minioadmin / minioadmin | S3 storage browser |
| **Ingestion API** | http://localhost:30080 | None | Telemetry endpoint |

## 📈 Grafana Dashboards

### Currently Provisioned Dashboards

### 1. F1 Telemetry - Race Weekend Dashboard (Custom)

**Purpose**: Visualize live race telemetry data from the 2024 Bahrain Grand Prix

**Panels**:
- 🏎️ **System Status**: Number of running pods (green = healthy)
- 📊 **Telemetry Ingestion Rate**: Success vs error rates for incoming data
- ⛽ **Pit Stop Telemetry**: Count of pit stop events received (last 5 minutes)
- 🏁 **Qualifying Data**: Count of qualifying session data received
- 🏆 **Race Results**: Count of race result updates received
- ✅ **Success Rate**: Percentage of successful telemetry ingestion (gauge)
- 📈 **Request Latency (p95)**: 95th and 50th percentile processing times
- ☁️ **S3 Upload Performance**: MinIO upload duration metrics
- 🔄 **Telemetry by Type**: Pie chart showing distribution of data types
- 📡 **Edge Devices Active**: Table of active edge simulator pods
- ⚡ **Request Rate**: Total requests per second over last 30 minutes

**Access**: Navigate to **Dashboards → Browse → F1 Telemetry - Race Weekend Dashboard**

### 2. Kubernetes Cluster - F1 Platform

**Purpose**: Monitor the underlying Kubernetes infrastructure

**Panels**:
- 🖥️ **Cluster Nodes**: Total nodes in the cluster
- 📦 **Total Pods**: All pods in default namespace
- ✅ **Running Pods**: Healthy running pods
- 🔧 **HPA Status**: Current replica count from autoscaler
- 💻 **CPU Usage by Pod**: CPU consumption per pod over time
- 🧠 **Memory Usage by Pod**: Memory consumption per pod (MB)
- 📊 **Pod Status by Phase**: Distribution of pod states (pie chart)
- 🔄 **Pod Restarts**: Restart count in last hour (troubleshooting)
- ⚖️ **HPA Target vs Current**: Autoscaler behavior visualization
- 🌐 **Network I/O by Pod**: RX/TX bandwidth per pod

**Access**: Navigate to **Dashboards → Browse → Kubernetes Cluster - F1 Platform**

### 🌐 Import Popular Public Dashboards (Optional - Great for Demo!)

You can easily import professional Kubernetes dashboards from [grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards):

**Recommended Public Dashboards:**

| Dashboard | ID | Description |
|-----------|-----|-------------|
| **Kubernetes Cluster (Prometheus)** | 6417 | Comprehensive cluster monitoring with kube-state-metrics |
| **Kubernetes Cluster Monitoring** | 7249 | Pod/container metrics, resource usage |
| **Kubernetes / Views / Global** | 15759 | Global cluster overview (requires newer metrics) |
| **Node Exporter Full** | 1860 | Detailed node metrics (if node-exporter is deployed) |
| **Prometheus Stats** | 2 | Monitor Prometheus itself |

**How to Import (Takes 30 seconds):**

1. Go to http://localhost:30030
2. Click **+** icon → **Import dashboard**
3. Enter dashboard ID (e.g., `6417`)
4. Click **Load**
5. Select **Prometheus** as data source
6. Click **Import**

**Pro Tip for Demo**: Import dashboard `6417` live during your screen recording to show:
- Familiarity with Grafana ecosystem
- How easy it is to add professional monitoring
- Access to 10,000+ community dashboards

This is more impressive than pre-loaded dashboards!

## 🚀 Quick Demo Flow

### Step 1: Open Grafana
```bash
open http://localhost:30030
# Login: admin / admin
```

### Step 2: View Live Telemetry Dashboard
1. Go to **Dashboards → Browse**
2. Click **F1 Telemetry - Race Weekend Dashboard**
3. Set refresh to **5s** (top right)
4. Watch live data flowing from the edge simulator

**What you'll see**:
- ⛽ Pit stop events incrementing every 30 seconds
- 🏁 Qualifying data being replayed
- ✅ Success rate at ~100% (green gauge)
- 📊 Steady ingestion rate graph climbing

### Step 3: View Cluster Health Dashboard
1. Go back to **Dashboards → Browse**
2. Click **Kubernetes Cluster - F1 Platform**
3. Observe:
   - All 7 pods running (green status)
   - CPU/Memory usage stable
   - HPA maintaining 2 ingestion service replicas
   - Network traffic flowing

### Step 4: Check Raw Metrics (Optional)
```bash
open http://localhost:30090
```

Try these PromQL queries:
```promql
# Total telemetry requests
sum(telemetry_requests_total)

# Success rate
sum(rate(telemetry_requests_total{status="success"}[5m]))
/ sum(rate(telemetry_requests_total[5m])) * 100

# Pit stop events
sum(increase(telemetry_requests_total{data_type="pit_stops"}[5m]))
```

### Step 5: Browse Stored Data in MinIO
```bash
open http://localhost:30901
# Login: minioadmin / minioadmin
```

Navigate to the **f1-telemetry-raw** bucket to see stored telemetry files organized by:
- `year=2024/`
- `season=2024/`
- `race=bahrain/`
- `data_type=pit_stops|qualifying|race_results/`

## 🎥 Screen Recording Tips

### What to Show:
1. **Architecture Overview** (30 sec)
   - Explain edge simulator → ingestion service → MinIO → Prometheus → Grafana

2. **Live Data Flow** (2 min)
   - Open F1 Telemetry Dashboard
   - Point out live metrics updating
   - Highlight success rate gauge at 100%
   - Show pit stop/qualifying counters incrementing

3. **Kubernetes Infrastructure** (1 min)
   - Switch to Kubernetes Cluster Dashboard
   - Show all pods healthy
   - Point out HPA managing 2 replicas
   - Show CPU/memory stable

4. **Data Storage** (1 min)
   - Open MinIO console
   - Navigate bucket structure
   - Show partitioned data files
   - Explain S3-compatible storage

5. **Edge Simulator Logs** (30 sec)
   ```bash
   kubectl logs -l app=edge-simulator --tail=20
   ```
   - Show replay cycle messages
   - Highlight successful transmissions

### Key Talking Points:
- ✅ **Cloud-native**: Kubernetes-based, horizontally scalable
- ✅ **Observability**: Full Prometheus + Grafana stack
- ✅ **Data Engineering**: S3-compatible storage with partitioning
- ✅ **Edge Computing**: Simulated trackside data collection
- ✅ **Production Ready**: HPA, PDB, health checks, resource limits
- ✅ **Cost Efficient**: Runs entirely on local kind cluster

## 🔍 Troubleshooting

### Dashboard shows "No data"
```bash
# Check if metrics are being exposed
curl http://localhost:30080/metrics

# Verify Prometheus is scraping
# Go to http://localhost:30090/targets
# All targets should be "UP"
```

### Edge simulator not sending data
```bash
# Check logs
kubectl logs -l app=edge-simulator --tail=50

# Should see: "✅ Successfully sent X telemetry to cloud"
```

### Ingestion service errors
```bash
# Check logs
kubectl logs -l app=ingestion-service --tail=50

# Should see: "POST /api/v1/telemetry HTTP/1.1" 202 Accepted
```

## 📊 Current Data Flow Status

**✅ All Systems Operational**

```
Edge Simulator (Replay Mode)
    ↓ Every 30s
    ↓ Replaying: 2024 Bahrain GP
    ↓
Ingestion Service (2 replicas)
    ↓ 202 Accepted
    ↓ Store to MinIO
    ↓
MinIO (S3-compatible)
    ↓ Buckets: f1-telemetry-raw, f1-telemetry-processed
    ↓
Prometheus (Metrics Collection)
    ↓ Scrape every 15s
    ↓
Grafana (Visualization)
    ✨ Live Dashboards
```

**Data Types Being Replayed**:
- ⛽ **Pit Stops**: ✅ Active (Bahrain GP pit stop data)
- 🏁 **Qualifying**: ✅ Active (VER P1, PER P2)
- 🏆 **Race Results**: ✅ Active (VER 1st, PER 2nd, SAI 3rd)

**Metrics Being Collected**:
- `telemetry_requests_total` - Total requests by status, data_type
- `telemetry_processing_duration_seconds` - Request latency histogram
- `s3_upload_duration_seconds` - Storage performance histogram
- Standard Kubernetes metrics (CPU, memory, network, pod status)

---

**Ready for Demo!** 🎬

Access Grafana at http://localhost:30030 (admin/admin) and start exploring the dashboards.
