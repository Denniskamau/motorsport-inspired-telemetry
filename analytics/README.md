# F1 Telemetry Analytics

AWS Glue and Athena configuration for analyzing F1 telemetry data.

## Architecture

```
S3 Raw Data → Glue Crawler → Glue Catalog → Athena → Insights
```

## Components

### AWS Glue
- **Database**: `f1_telemetry`
- **Crawler**: Automatically discovers schema from S3 data
- **Schedule**: Runs every 6 hours to discover new partitions
- **Tables**: Created automatically based on S3 data structure

### AWS Athena
- **Workgroup**: `f1-telemetry-{environment}`
- **Query Results**: Stored in dedicated S3 bucket
- **Partitioning**: Year/Month/Day/DataType for efficient queries
- **Cost Optimization**: Partition projection enabled

## Setup

### Prerequisites

- Terraform infrastructure deployed
- S3 buckets created
- IAM roles configured
- AWS CLI configured

### 1. Setup Glue

```bash
cd analytics/glue

# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev

# Run setup script
chmod +x setup.sh
./setup.sh
```

This will:
- Create Glue database `f1_telemetry`
- Create and start crawler
- Discover schema from S3 data

### 2. Setup Athena

```bash
cd analytics/athena

# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev

# Run setup script
chmod +x setup.sh
./setup.sh
```

This will:
- Create Athena workgroup
- Configure query results location

### 3. Wait for Crawler

```bash
# Check crawler status
aws glue get-crawler --name f1-telemetry-raw-crawler

# Wait until state is "READY"
```

### 4. Run Queries

#### Using AWS Console

1. Go to Athena Console
2. Select workgroup: `f1-telemetry-dev`
3. Select database: `f1_telemetry`
4. Copy queries from `analytics/athena/queries/`
5. Execute

#### Using AWS CLI

```bash
# Update query files with your environment
sed -i 's/<ENVIRONMENT>/dev/g' analytics/athena/queries/*.sql

# Run lap times analysis
aws athena start-query-execution \
  --query-string "$(cat analytics/athena/queries/lap_times_analysis.sql)" \
  --result-configuration "OutputLocation=s3://f1-telemetry-dev-athena-results/" \
  --work-group "f1-telemetry-dev" \
  --region us-east-1

# Get query execution ID from output, then check status
aws athena get-query-execution --query-execution-id <EXECUTION_ID>
```

## Available Queries

### 1. Lap Times Analysis
**File**: `lap_times_analysis.sql`

Analyzes lap time data:
- Race date aggregation
- Edge device statistics
- Collection time ranges

### 2. Pit Stop Analysis
**File**: `pit_stop_analysis.sql`

Analyzes pit stop data:
- Pit stop records per race
- Collection duration
- Edge device performance

### 3. Ingestion Metrics
**File**: `ingestion_metrics.sql`

Monitors data ingestion:
- Hourly ingestion rates
- Moving averages
- Data flow patterns

### 4. Data Quality
**File**: `data_quality.sql`

Data quality checks:
- Missing data detection
- Record count validation
- Coverage analysis

## Data Partitioning

The data is partitioned for optimal query performance:

```
s3://bucket/raw-telemetry/
  year=2025/
    month=12/
      day=31/
        data_type=lap_times/
        data_type=pit_stops/
        data_type=race_results/
        data_type=qualifying/
```

### Partition Projection

Tables use partition projection to avoid needing explicit `MSCK REPAIR TABLE`:

```sql
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.year.type' = 'integer',
  'projection.year.range' = '2024,2030',
  ...
)
```

This allows Athena to automatically understand partitions without scanning S3.

## Query Optimization Tips

### 1. Always Filter by Partition

```sql
-- Good
WHERE year = 2025 AND month = 12 AND day = 31

-- Bad (scans all data)
WHERE timestamp > '2025-12-31'
```

### 2. Use LIMIT for Testing

```sql
SELECT * FROM table LIMIT 100
```

### 3. Analyze Before Running

```sql
-- Check how much data will be scanned
EXPLAIN SELECT * FROM table WHERE year = 2025
```

### 4. Use Columnar Formats (Future Enhancement)

Convert JSON to Parquet for better performance:

```sql
CREATE TABLE processed_telemetry
WITH (
  format = 'PARQUET',
  parquet_compression = 'SNAPPY'
) AS
SELECT * FROM raw_telemetry
```

## Race Weekend Analytics

### Pre-Race Analysis

```sql
-- Verify data collection is working
SELECT
  data_type,
  COUNT(*) as records,
  MAX(timestamp) as latest_data
FROM f1_telemetry.raw_telemetry
WHERE year = 2025
  AND month = 12
  AND day = 31
GROUP BY data_type
```

### Real-Time Monitoring (During Race)

```sql
-- Check ingestion in last hour
SELECT
  date_trunc('minute', from_iso8601_timestamp(timestamp)) as minute,
  data_type,
  COUNT(*) as records
FROM f1_telemetry.raw_telemetry
WHERE timestamp > date_format(date_add('hour', -1, now()), '%Y-%m-%dT%H:%i:%s')
GROUP BY
  date_trunc('minute', from_iso8601_timestamp(timestamp)),
  data_type
ORDER BY minute DESC
```

### Post-Race Analysis

```sql
-- Complete race analysis
SELECT
  data_type,
  COUNT(*) as total_records,
  MIN(timestamp) as race_start,
  MAX(timestamp) as race_end,
  COUNT(DISTINCT edge_id) as edge_devices
FROM f1_telemetry.raw_telemetry
WHERE year = 2025
  AND month = 12
  AND day = 31
GROUP BY data_type
```

## Monitoring and Alerts

### CloudWatch Integration

Athena workgroup publishes metrics to CloudWatch:

- Query execution time
- Data scanned
- Query success/failure rates

### Cost Monitoring

```bash
# Check data scanned (cost = $5 per TB scanned)
aws athena get-query-execution \
  --query-execution-id <EXECUTION_ID> \
  --query 'QueryExecution.Statistics.DataScannedInBytes'
```

## Troubleshooting

### Crawler Not Finding Data

```bash
# Check S3 bucket has data
aws s3 ls s3://f1-telemetry-dev-raw-telemetry/raw-telemetry/ --recursive | head

# Manually run crawler
aws glue start-crawler --name f1-telemetry-raw-crawler
```

### Table Not Found

```sql
-- Refresh partitions (if not using partition projection)
MSCK REPAIR TABLE f1_telemetry.raw_telemetry;

-- Or manually add partition
ALTER TABLE f1_telemetry.raw_telemetry
ADD PARTITION (year=2025, month=12, day=31, data_type_partition='lap_times')
LOCATION 's3://f1-telemetry-dev-raw-telemetry/raw-telemetry/year=2025/month=12/day=31/data_type=lap_times/';
```

### Permission Errors

```bash
# Verify IAM role has Glue and S3 permissions
aws iam get-role --role-name f1-telemetry-dev-glue
aws iam list-attached-role-policies --role-name f1-telemetry-dev-glue
```

## Future Enhancements

1. **Glue ETL Jobs**: Transform JSON to Parquet
2. **QuickSight Dashboards**: Visualize analytics
3. **Automated Alerts**: Lambda functions for anomaly detection
4. **Machine Learning**: SageMaker integration for predictions
5. **Data Catalog Tags**: Classification and governance
