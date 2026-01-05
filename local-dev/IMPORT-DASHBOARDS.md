# 📊 Import Public Grafana Dashboards

## ✅ Ready to Import

Your system now has **kube-state-metrics** deployed and Prometheus configured to scrape it. This means you can import professional public Kubernetes dashboards from [grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards).

## 🎯 Recommended Dashboards to Import

### 1. Kubernetes Cluster (Prometheus) - ID: 6417
**Best for**: Comprehensive cluster overview
- Pod, CPU, memory, disk usage gauges
- Capacity vs allocatable tracking
- Deployment status
- Node health
- Container states

**Import Steps**:
1. Open Grafana: http://localhost:30030 (admin/admin)
2. Click **+** (plus icon) in left sidebar → **Import dashboard**
3. Enter dashboard ID: `6417`
4. Click **Load**
5. Select **Prometheus** as the data source
6. Click **Import**

### 2. Kubernetes Cluster Monitoring (via Prometheus) - ID: 7249
**Best for**: Detailed pod and container metrics
- Resource requests/limits
- Network I/O
- Pod lifecycle states
- Container restart tracking

**Import Steps**: Same as above, use ID `7249`

### 3. Node Exporter Full - ID: 1860
**Best for**: Detailed node-level metrics (requires node-exporter)
- Not currently deployed, but shows what's possible

### 4. Prometheus 2.0 Stats - ID: 3662
**Best for**: Monitor Prometheus itself
- Scrape duration
- Target status
- TSDB stats

## 🎥 Demo Strategy

### Option A: Import Before Recording
Import dashboards 6417 and 7249 before starting your screen recording, so they're ready to show.

### Option B: Import During Recording (More Impressive!)
1. Start screen recording
2. Show your custom F1 Telemetry dashboard first
3. Then say: "Let me show how easy it is to add professional Kubernetes monitoring"
4. Import dashboard 6417 live (takes 30 seconds)
5. Navigate through the imported dashboard
6. Highlight: "Access to 10,000+ community dashboards"

**Why Option B is better**:
- Demonstrates hands-on skills
- Shows familiarity with Grafana ecosystem
- More engaging than just clicking through pre-loaded dashboards
- Interviewer sees the import process is trivial

## 📊 Current Dashboard Summary

### Custom Dashboards (Already Loaded)
1. **F1 Telemetry - Race Weekend Dashboard**
   - Location: Dashboards → Browse → "F1 Telemetry - Race Weekend Dashboard"
   - Custom metrics for pit stops, qualifying, race results
   - Success rates, latency, ingestion performance

2. **Kubernetes Cluster - F1 Platform**
   - Location: Dashboards → Browse → "Kubernetes Cluster - F1 Platform"
   - Custom built for this demo
   - Pod status, CPU/memory, HPA, network I/O

### After Import (ID 6417 and 7249)
You'll have **4 total dashboards**:
- 2 custom motorsport-focused
- 2 professional community Kubernetes dashboards

This combination shows:
- Domain expertise (F1 telemetry)
- Infrastructure skills (Kubernetes)
- Cloud-native best practices (observability)
- Practical experience (using Grafana ecosystem)

## 🔍 Verify Metrics Are Available

Before importing, verify kube-state-metrics is working:

```bash
# Open Prometheus
open http://localhost:30090

# Try these queries:
kube_pod_info
kube_pod_status_phase
kube_deployment_status_replicas
```

If you see results, you're ready to import!

## 🚨 Troubleshooting

### Dashboard shows "No data"
1. Check Prometheus targets: http://localhost:30090/targets
2. Verify `kube-state-metrics` target is UP
3. Wait 30 seconds for data to populate
4. Refresh dashboard

### kube-state-metrics not showing
```bash
kubectl get pods -n kube-system | grep kube-state-metrics
# Should show: kube-state-metrics-xxx  1/1  Running
```

### Prometheus not scraping
```bash
# Check Prometheus logs
kubectl logs -n default deployment/prometheus --tail=50

# Should see: "Successfully scraped kube-state-metrics"
```

## 💡 Pro Tips

1. **Set Time Range**: Most dashboards default to "Last 1 hour" - adjust in top right
2. **Enable Auto-Refresh**: Set to 10s or 30s for live updates
3. **Star Favorites**: Click star icon to add dashboards to favorites
4. **Create Playlists**: Dashboards → Playlists → Create rotation for TV display
5. **Snapshot**: Share → Snapshot → Create snapshot link to share with others

## 🎬 Demo Script Addition

Add this to your demo flow:

**After showing F1 Telemetry dashboard:**

> "Now, one of the powerful features of Grafana is access to thousands of community dashboards. Let me show you how easy it is to add professional Kubernetes monitoring..."
>
> [Click + → Import → Enter 6417 → Load → Select Prometheus → Import]
>
> "In 30 seconds, we now have a comprehensive cluster monitoring dashboard built by the community. This is dashboard ID 6417, one of the most popular Kubernetes dashboards with detailed pod, container, and resource metrics."
>
> [Navigate through panels]
>
> "This demonstrates not just that we can build custom dashboards for domain-specific needs like F1 telemetry, but we can also leverage the ecosystem for standard infrastructure monitoring. And this is just one of over 10,000 available dashboards."

This shows:
- ✅ Technical skills
- ✅ Ecosystem knowledge
- ✅ Practical efficiency (don't reinvent the wheel)
- ✅ Live demonstration ability

---

**Ready!** Your system is configured to import any Kubernetes dashboard from grafana.com that uses Prometheus and kube-state-metrics.
