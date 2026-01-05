# F1 Telemetry Ingestion Service

FastAPI service for receiving telemetry data from edge devices and storing it in S3.

## Features

- RESTful API for telemetry ingestion
- S3 storage with intelligent partitioning (year/month/day/data_type)
- Prometheus metrics for observability
- Health check endpoints
- Request validation with Pydantic
- Graceful error handling and retry logic

## API Endpoints

### POST /api/v1/telemetry
Ingest telemetry data from edge devices.

**Request Body:**
```json
{
  "timestamp": "2025-12-31T12:00:00Z",
  "edge_id": "edge-simulator-001",
  "data_type": "lap_times",
  "payload": { ... },
  "metadata": {
    "collection_time": "2025-12-31T12:00:00Z",
    "source": "ergast-api",
    "version": "1.0.0"
  }
}
```

**Response:**
```json
{
  "status": "accepted",
  "s3_key": "raw-telemetry/year=2025/month=12/day=31/...",
  "timestamp": "2025-12-31T12:00:01Z"
}
```

### GET /health
Health check endpoint.

### GET /metrics
Prometheus metrics endpoint.

## Usage

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run service
uvicorn main:app --reload --port 8000

# Test endpoint
curl http://localhost:8000/health
```

### Docker

```bash
# Build image
docker build -t f1-ingestion-service:latest .

# Run container
docker run -p 8000:8000 \
           -e S3_BUCKET_NAME=f1-telemetry-raw \
           -e AWS_REGION=us-east-1 \
           -e AWS_ACCESS_KEY_ID=your-key \
           -e AWS_SECRET_ACCESS_KEY=your-secret \
           f1-ingestion-service:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8000` | Service port |
| `S3_BUCKET_NAME` | `f1-telemetry-raw` | S3 bucket for raw telemetry |
| `AWS_REGION` | `us-east-1` | AWS region |
| `AWS_ACCESS_KEY_ID` | - | AWS credentials (use IRSA in EKS) |
| `AWS_SECRET_ACCESS_KEY` | - | AWS credentials (use IRSA in EKS) |

## Metrics

The service exposes Prometheus metrics at `/metrics`:

- `telemetry_requests_total` - Total telemetry requests by data type and status
- `telemetry_processing_duration_seconds` - Processing time histogram
- `s3_upload_duration_seconds` - S3 upload time histogram

## S3 Storage Structure

Data is stored with the following partitioning scheme for efficient Athena queries:

```
s3://bucket-name/
  raw-telemetry/
    year=2025/
      month=12/
        day=31/
          data_type=lap_times/
            edge-simulator-001_2025-12-31T12:00:00.json
          data_type=pit_stops/
            edge-simulator-001_2025-12-31T12:05:00.json
```
