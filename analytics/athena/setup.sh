#!/bin/bash
# Setup script for AWS Athena

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
WORKGROUP_NAME="f1-telemetry-${ENVIRONMENT}"
OUTPUT_BUCKET="f1-telemetry-${ENVIRONMENT}-athena-results"

echo "Setting up AWS Athena for F1 Telemetry Analytics"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo "Workgroup: $WORKGROUP_NAME"

# Create Athena workgroup
echo "Creating Athena workgroup..."
aws athena create-work-group \
  --name "$WORKGROUP_NAME" \
  --configuration "ResultConfigurationUpdates={
    OutputLocation=s3://${OUTPUT_BUCKET}/,
    EncryptionConfiguration={EncryptionOption=SSE_S3}
  },EnforceWorkGroupConfiguration=true,PublishCloudWatchMetricsEnabled=true" \
  --description "Workgroup for F1 telemetry analytics" \
  --region "$AWS_REGION" || echo "Workgroup already exists"

echo "Athena setup complete!"
echo ""
echo "To run queries:"
echo "1. Update queries in analytics/athena/queries/ with your environment"
echo "2. Run queries via AWS Console or CLI:"
echo "   aws athena start-query-execution \\"
echo "     --query-string \"\$(cat analytics/athena/queries/lap_times_analysis.sql)\" \\"
echo "     --result-configuration \"OutputLocation=s3://${OUTPUT_BUCKET}/\" \\"
echo "     --work-group \"$WORKGROUP_NAME\" \\"
echo "     --region \"$AWS_REGION\""
