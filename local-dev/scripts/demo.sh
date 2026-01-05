#!/bin/bash
# Demo script - shows key metrics and URLs for screen recording

echo "🏎️  F1 Telemetry Platform - Demo"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🌐 Access URLs:${NC}"
echo "  MinIO Console:     http://localhost:9001"
echo "  Ingestion Service: http://localhost:30080/health"
echo "  Prometheus:        http://localhost:30090"
echo "  Grafana:           http://localhost:30030"
echo ""

echo -e "${CYAN}📊 Kubernetes Status:${NC}"
echo ""
kubectl get nodes
echo ""
kubectl get pods -o wide
echo ""
kubectl get svc
echo ""

echo -e "${CYAN}📈 HPA Status:${NC}"
kubectl get hpa
echo ""

echo -e "${CYAN}🔍 Recent Logs (Ingestion Service):${NC}"
kubectl logs -l app=ingestion-service --tail=10
echo ""

echo -e "${CYAN}🔍 Recent Logs (Edge Simulator):${NC}"
kubectl logs -l app=edge-simulator --tail=10
echo ""

echo -e "${CYAN}📊 MinIO Buckets:${NC}"
docker exec f1-minio mc ls myminio/
echo ""

echo -e "${CYAN}💡 Demo Commands:${NC}"
echo "  # Watch pods in real-time"
echo "  watch kubectl get pods"
echo ""
echo "  # Stream logs"
echo "  kubectl logs -f deployment/ingestion-service"
echo ""
echo "  # Test ingestion endpoint"
echo "  curl http://localhost:30080/health"
echo ""
echo "  # View metrics"
echo "  curl http://localhost:30080/metrics"
echo ""
echo "  # Check MinIO data"
echo "  docker exec f1-minio mc ls myminio/f1-telemetry-raw/raw-telemetry/ --recursive"
echo ""

echo -e "${GREEN}✅ System is running!${NC}"
echo ""
echo "Press Ctrl+C to exit this view"
