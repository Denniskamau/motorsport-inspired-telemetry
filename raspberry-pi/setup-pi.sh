#!/bin/bash

# F1 Telemetry Platform - Raspberry Pi Setup Script
# This script automates the deployment of the F1 telemetry platform on Raspberry Pi with k3s

set -e

echo "🏎️  F1 Telemetry Platform - Raspberry Pi Setup"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running on Raspberry Pi
check_platform() {
    echo "Checking platform..."
    if [ ! -f /proc/device-tree/model ]; then
        print_warning "Not running on Raspberry Pi, but continuing anyway..."
    else
        MODEL=$(cat /proc/device-tree/model)
        print_status "Running on: $MODEL"
    fi
}

# Check prerequisites
check_prerequisites() {
    echo ""
    echo "Checking prerequisites..."

    # Check for external storage
    if [ ! -d "/data" ]; then
        print_error "/data directory not found. Please mount your external SSD first!"
        echo "See RASPBERRY-PI-DEPLOYMENT.md Step 2 for instructions."
        exit 1
    fi
    print_status "/data directory exists"

    # Check available disk space
    DISK_SPACE=$(df -BG /data | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 50 ]; then
        print_warning "Low disk space on /data: ${DISK_SPACE}GB (recommended: 50GB+)"
    else
        print_status "Sufficient disk space: ${DISK_SPACE}GB"
    fi

    # Check memory
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 3 ]; then
        print_warning "Low memory: ${TOTAL_MEM}GB (recommended: 4GB+)"
    else
        print_status "Sufficient memory: ${TOTAL_MEM}GB"
    fi
}

# Install k3s
install_k3s() {
    echo ""
    echo "Installing k3s..."

    if command -v k3s &> /dev/null; then
        print_status "k3s already installed ($(k3s --version | head -1))"
        return
    fi

    curl -sfL https://get.k3s.io | sh -s - \
        --write-kubeconfig-mode 644 \
        --data-dir /data/k3s-data \
        --disable traefik

    # Wait for k3s to be ready
    echo "Waiting for k3s to start..."
    sleep 10

    # Setup kubeconfig
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $USER:$USER ~/.kube/config

    print_status "k3s installed successfully"
}

# Check k3s status
check_k3s() {
    echo ""
    echo "Checking k3s status..."

    if ! sudo systemctl is-active --quiet k3s; then
        print_error "k3s service is not running"
        exit 1
    fi
    print_status "k3s service is running"

    # Wait for node to be ready
    echo "Waiting for node to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=60s
    print_status "Node is ready"
}

# Build or import Docker images
handle_images() {
    echo ""
    echo "Handling Docker images..."

    read -p "Do you want to build images on this Pi? (y/n - 'n' means you'll scp them from your Mac): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Building images (this may take 20+ minutes)..."

        cd "$(dirname "$0")/.."

        docker build -t f1-edge-simulator:latest ./edge-simulator
        docker build -t f1-ingestion-service:latest ./ingestion-service

        # Save and import to k3s
        echo "Importing images to k3s..."
        docker save f1-edge-simulator:latest | sudo k3s ctr images import -
        docker save f1-ingestion-service:latest | sudo k3s ctr images import -

        print_status "Images built and imported"
    else
        print_warning "Skipping image build. You need to:"
        echo "  1. Build on your Mac: docker buildx build --platform linux/arm64 ..."
        echo "  2. Save: docker save IMAGE | gzip > image.tar.gz"
        echo "  3. Copy: scp image.tar.gz pi@raspberrypi:~"
        echo "  4. Import: gunzip -c image.tar.gz | sudo k3s ctr images import -"
        echo ""
        read -p "Press enter when images are imported..."
    fi
}

# Deploy Kubernetes resources
deploy_resources() {
    echo ""
    echo "Deploying Kubernetes resources..."

    cd "$(dirname "$0")/k8s"

    # Deploy in order
    echo "Deploying MinIO..."
    kubectl apply -f minio.yaml
    print_status "MinIO deployed"

    echo "Deploying Prometheus..."
    kubectl apply -f prometheus.yaml
    print_status "Prometheus deployed"

    echo "Deploying kube-state-metrics..."
    kubectl apply -f kube-state-metrics.yaml
    print_status "kube-state-metrics deployed"

    echo "Deploying Grafana dashboards..."
    kubectl apply -f grafana-dashboards.yaml
    print_status "Grafana dashboards deployed"

    echo "Deploying Grafana..."
    kubectl apply -f grafana.yaml
    print_status "Grafana deployed"

    echo "Deploying Ingestion Service..."
    kubectl apply -f ingestion-service.yaml
    print_status "Ingestion Service deployed"

    echo "Deploying Edge Simulator..."
    kubectl apply -f edge-simulator.yaml
    print_status "Edge Simulator deployed"
}

# Wait for pods
wait_for_pods() {
    echo ""
    echo "Waiting for all pods to be ready (this may take 5-10 minutes)..."

    kubectl wait --for=condition=Ready pods --all -n default --timeout=600s || true
    kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=600s || true

    echo ""
    echo "Pod status:"
    kubectl get pods --all-namespaces
}

# Show access information
show_access_info() {
    echo ""
    echo "================================================"
    echo "🎉 Setup Complete!"
    echo "================================================"
    echo ""
    echo "Access URLs (from this Pi):"
    echo "  Grafana:    http://localhost:30030 (admin/admin)"
    echo "  Prometheus: http://localhost:30090"
    echo "  MinIO:      http://localhost:30901 (minioadmin/minioadmin)"
    echo ""
    echo "Next steps:"
    echo "  1. Test locally: curl http://localhost:30030"
    echo "  2. Setup Cloudflare Tunnel (see RASPBERRY-PI-DEPLOYMENT.md Step 5)"
    echo "  3. Configure public access"
    echo ""
    echo "Monitor your cluster:"
    echo "  kubectl get pods --watch"
    echo "  kubectl logs -f deployment/edge-simulator"
    echo ""
    echo "Check Pi temperature:"
    echo "  vcgencmd measure_temp"
    echo ""
}

# Main execution
main() {
    check_platform
    check_prerequisites
    install_k3s
    check_k3s
    handle_images
    deploy_resources
    wait_for_pods
    show_access_info
}

# Run main function
main
