#!/bin/bash
# Setup script for local F1 Telemetry Demo Environment

set -e

echo "🏎️  F1 Telemetry Platform - Local Setup"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

MISSING_DEPS=0

check_command "docker" || MISSING_DEPS=1
check_command "kubectl" || MISSING_DEPS=1
check_command "kind" || MISSING_DEPS=1

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Missing dependencies. Please install:${NC}"
    echo "  - Docker Desktop: https://www.docker.com/products/docker-desktop"
    echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

echo ""
echo "🐳 Starting Docker services (MinIO, Prometheus, Grafana)..."
cd "$(dirname "$0")/.."
docker-compose up -d

echo ""
echo "⏳ Waiting for MinIO to be ready..."
until curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}✓${NC} MinIO is ready"

echo ""
echo "🔧 Building Docker images..."
cd ../..

# Build edge simulator
echo "  Building edge-simulator..."
docker build -t f1-edge-simulator:latest ./edge-simulator

# Build ingestion service
echo "  Building ingestion-service..."
docker build -t f1-ingestion-service:latest ./ingestion-service

echo ""
echo "🎯 Creating kind cluster..."
if kind get clusters | grep -q "f1-telemetry"; then
    echo -e "${YELLOW}Cluster 'f1-telemetry' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name f1-telemetry
        kind create cluster --name f1-telemetry --config local-dev/scripts/kind-config.yaml
    fi
else
    kind create cluster --name f1-telemetry --config local-dev/scripts/kind-config.yaml
fi

echo ""
echo "📦 Loading Docker images into kind..."
kind load docker-image f1-edge-simulator:latest --name f1-telemetry
kind load docker-image f1-ingestion-service:latest --name f1-telemetry

echo ""
echo "☸️  Deploying to Kubernetes..."
kubectl apply -f local-dev/k8s/metrics-server.yaml
echo "  Waiting for metrics-server..."
sleep 10

kubectl apply -f local-dev/k8s/ingestion-service.yaml
kubectl apply -f local-dev/k8s/edge-simulator.yaml
kubectl apply -f local-dev/k8s/prometheus.yaml
kubectl apply -f local-dev/k8s/grafana.yaml

echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/ingestion-service
kubectl wait --for=condition=available --timeout=60s deployment/edge-simulator
kubectl wait --for=condition=available --timeout=60s deployment/prometheus
kubectl wait --for=condition=available --timeout=60s deployment/grafana

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "🌐 Access URLs:"
echo "  • MinIO Console:     http://localhost:9001  (minioadmin / minioadmin)"
echo "  • MinIO API:         http://localhost:9000"
echo "  • Ingestion Service: http://localhost:30080"
echo "  • Prometheus:        http://localhost:30090"
echo "  • Grafana:           http://localhost:30030  (admin / admin)"
echo ""
echo "📊 Kubernetes Dashboard:"
echo "  kubectl get pods"
echo "  kubectl get svc"
echo ""
echo "🔍 View logs:"
echo "  kubectl logs -f deployment/ingestion-service"
echo "  kubectl logs -f deployment/edge-simulator"
echo ""
echo "🧹 To tear down:"
echo "  ./local-dev/scripts/teardown.sh"
echo ""
