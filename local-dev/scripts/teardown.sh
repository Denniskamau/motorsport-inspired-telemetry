#!/bin/bash
# Teardown script for local F1 Telemetry Demo Environment

set -e

echo "🧹 F1 Telemetry Platform - Teardown"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

read -p "This will delete the kind cluster and stop Docker services. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting kind cluster..."
if kind get clusters | grep -q "f1-telemetry"; then
    kind delete cluster --name f1-telemetry
    echo -e "${GREEN}✓${NC} Cluster deleted"
else
    echo -e "${YELLOW}!${NC} Cluster not found"
fi

echo ""
echo "🐳 Stopping Docker services..."
cd "$(dirname "$0")/.."
docker-compose down

echo ""
echo -e "${GREEN}✅ Teardown complete!${NC}"
echo ""
