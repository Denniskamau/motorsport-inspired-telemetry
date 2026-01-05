#!/bin/bash
# Test script to manually trigger telemetry ingestion

echo "🧪 Testing Ingestion Service"
echo "============================"
echo ""

# Test payload
PAYLOAD='{
  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "edge_id": "test-device-001",
  "data_type": "test_data",
  "payload": {
    "test": true,
    "message": "Manual test from demo"
  },
  "metadata": {
    "collection_time": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "source": "manual-test",
    "version": "1.0.0"
  }
}'

echo "Sending test telemetry..."
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST \
  http://localhost:30080/api/v1/telemetry \
  -H "Content-Type: application/json" \
  -H "X-Edge-ID: test-device-001" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" == "202" ]; then
    echo "✅ Success! Response:"
    echo "$BODY" | jq .
else
    echo "❌ Failed with HTTP $HTTP_CODE"
    echo "$BODY"
fi

echo ""
echo "Check data in MinIO:"
echo "  docker exec f1-minio mc ls myminio/f1-telemetry-raw/raw-telemetry/ --recursive"
