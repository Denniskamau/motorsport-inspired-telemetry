#!/bin/bash
# Setup script for AWS Glue

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Setting up AWS Glue for F1 Telemetry Analytics"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"

# Create Glue Database
echo "Creating Glue database..."
aws glue create-database \
  --region "$AWS_REGION" \
  --database-input "{
    \"Name\": \"f1_telemetry\",
    \"Description\": \"F1 telemetry data analytics database\"
  }" || echo "Database already exists"

# Update crawler configuration
echo "Updating crawler configuration..."
sed -e "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" \
    -e "s/<ENVIRONMENT>/$ENVIRONMENT/g" \
    crawler.json > crawler_updated.json

# Create or update Glue Crawler
echo "Creating Glue crawler..."
if aws glue get-crawler --name "f1-telemetry-raw-crawler" --region "$AWS_REGION" 2>/dev/null; then
  echo "Crawler exists, updating..."
  aws glue update-crawler \
    --region "$AWS_REGION" \
    --cli-input-json file://crawler_updated.json
else
  echo "Creating new crawler..."
  aws glue create-crawler \
    --region "$AWS_REGION" \
    --cli-input-json file://crawler_updated.json
fi

# Start crawler
echo "Starting crawler..."
aws glue start-crawler \
  --name "f1-telemetry-raw-crawler" \
  --region "$AWS_REGION" || echo "Crawler already running"

echo "Glue setup complete!"
echo ""
echo "Next steps:"
echo "1. Wait for crawler to complete (check AWS Console or run: aws glue get-crawler --name f1-telemetry-raw-crawler)"
echo "2. Run Athena queries in analytics/athena/"
