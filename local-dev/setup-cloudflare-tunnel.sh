#!/bin/bash

# Cloudflare Tunnel Setup Script for F1 Telemetry Platform
# Makes your local kind cluster publicly accessible

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TUNNEL_NAME="f1-telemetry"
BASE_DOMAIN="shiftup-dev.com"
CONFIG_FILE="$(pwd)/cloudflare-tunnel-config.yaml"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🏎️  F1 Telemetry - Cloudflare Tunnel Setup             ║${NC}"
echo -e "${BLUE}║  Making your local cluster publicly accessible           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check authentication
echo -e "${YELLOW}Step 1: Checking Cloudflare authentication...${NC}"
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo -e "${RED}✗ Not authenticated with Cloudflare${NC}"
    echo -e "${YELLOW}Please complete the authentication in your browser first.${NC}"
    echo ""
    echo "Run: cloudflared tunnel login"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated with Cloudflare${NC}"
echo ""

# Step 2: Check if tunnel exists
echo -e "${YELLOW}Step 2: Checking for existing tunnel...${NC}"
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo -e "${YELLOW}⚠ Tunnel '$TUNNEL_NAME' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing tunnel..."
        cloudflared tunnel delete $TUNNEL_NAME
    else
        echo "Using existing tunnel..."
        TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    fi
fi

# Step 3: Create tunnel if needed
if [ -z "$TUNNEL_ID" ]; then
    echo -e "${YELLOW}Step 3: Creating new tunnel '$TUNNEL_NAME'...${NC}"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo -e "${GREEN}✓ Tunnel created with ID: $TUNNEL_ID${NC}"
else
    echo -e "${GREEN}✓ Using tunnel ID: $TUNNEL_ID${NC}"
fi
echo ""

# Step 4: Update config file
echo -e "${YELLOW}Step 4: Updating configuration file...${NC}"
sed "s/TUNNEL_ID_PLACEHOLDER/$TUNNEL_ID/g" cloudflare-tunnel-config.yaml > ~/.cloudflared/config.yaml
echo -e "${GREEN}✓ Configuration saved to ~/.cloudflared/config.yaml${NC}"
echo ""

# Step 5: Configure DNS records
echo -e "${YELLOW}Step 5: Configuring DNS records...${NC}"
echo "Setting up the following subdomains:"
echo "  - telemetry.$BASE_DOMAIN (Grafana)"
echo "  - prometheus.$BASE_DOMAIN (Prometheus)"
echo "  - minio.$BASE_DOMAIN (MinIO Console)"
echo "  - api.$BASE_DOMAIN (Ingestion API)"
echo ""

cloudflared tunnel route dns $TUNNEL_NAME telemetry.$BASE_DOMAIN || true
cloudflared tunnel route dns $TUNNEL_NAME prometheus.$BASE_DOMAIN || true
cloudflared tunnel route dns $TUNNEL_NAME minio.$BASE_DOMAIN || true
cloudflared tunnel route dns $TUNNEL_NAME api.$BASE_DOMAIN || true

echo -e "${GREEN}✓ DNS records configured${NC}"
echo ""

# Step 6: Test configuration
echo -e "${YELLOW}Step 6: Testing configuration...${NC}"
if cloudflared tunnel info $TUNNEL_NAME &> /dev/null; then
    echo -e "${GREEN}✓ Tunnel configuration is valid${NC}"
else
    echo -e "${RED}✗ Tunnel configuration has errors${NC}"
    exit 1
fi
echo ""

# Step 7: Display next steps
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Cloudflare Tunnel Setup Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🚀 Your F1 Telemetry platform will be accessible at:${NC}"
echo ""
echo -e "  ${GREEN}Main Dashboard:${NC}  https://telemetry.${BASE_DOMAIN}"
echo -e "  ${GREEN}Prometheus:${NC}      https://prometheus.${BASE_DOMAIN}"
echo -e "  ${GREEN}MinIO Console:${NC}   https://minio.${BASE_DOMAIN}"
echo -e "  ${GREEN}Ingestion API:${NC}   https://api.${BASE_DOMAIN}"
echo ""
echo -e "${YELLOW}To start the tunnel, run:${NC}"
echo ""
echo -e "  ${BLUE}cloudflared tunnel run $TUNNEL_NAME${NC}"
echo ""
echo -e "${YELLOW}Or run as a background service:${NC}"
echo ""
echo -e "  ${BLUE}cloudflared tunnel run $TUNNEL_NAME &${NC}"
echo ""
echo -e "${YELLOW}To install as a system service (recommended):${NC}"
echo ""
echo -e "  ${BLUE}sudo cloudflared service install${NC}"
echo -e "  ${BLUE}sudo launchctl start com.cloudflare.cloudflared${NC}"
echo ""
echo -e "${GREEN}Credentials saved to:${NC} ~/.cloudflared/$TUNNEL_ID.json"
echo -e "${GREEN}Configuration:${NC} ~/.cloudflared/config.yaml"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
