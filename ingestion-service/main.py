"""
F1 Telemetry Ingestion Service
FastAPI service for receiving and storing telemetry data
"""
import os
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from contextlib import asynccontextmanager

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
telemetry_requests_total = Counter(
    'telemetry_requests_total',
    'Total number of telemetry requests',
    ['data_type', 'status']
)

telemetry_processing_duration = Histogram(
    'telemetry_processing_duration_seconds',
    'Time spent processing telemetry',
    ['data_type']
)

s3_upload_duration = Histogram(
    's3_upload_duration_seconds',
    'Time spent uploading to S3',
    ['bucket']
)


class TelemetryMetadata(BaseModel):
    """Metadata for telemetry data"""
    collection_time: str
    source: str
    version: str


class TelemetryPayload(BaseModel):
    """Telemetry data payload"""
    timestamp: str
    edge_id: str
    data_type: str
    payload: Dict[str, Any]
    metadata: TelemetryMetadata


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    timestamp: str
    version: str


class S3Storage:
    """Handles S3 storage operations (supports both AWS S3 and MinIO)"""

    def __init__(self, bucket_name: str, region: str = "us-east-1"):
        self.bucket_name = bucket_name
        self.region = region
        self.s3_client = None

        try:
            # Check if using MinIO (local development)
            s3_endpoint = os.environ.get("S3_ENDPOINT_URL")
            aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID", "minioadmin")
            aws_secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY", "minioadmin")

            if s3_endpoint:
                # MinIO configuration
                logger.info(f"Using S3-compatible storage at: {s3_endpoint}")
                self.s3_client = boto3.client(
                    's3',
                    endpoint_url=s3_endpoint,
                    aws_access_key_id=aws_access_key,
                    aws_secret_access_key=aws_secret_key,
                    region_name=region
                )
            else:
                # AWS S3 configuration
                self.s3_client = boto3.client('s3', region_name=region)

            logger.info(f"Initialized S3 client for bucket: {bucket_name}")
        except Exception as e:
            logger.error(f"Failed to initialize S3 client: {e}")

    def store_telemetry(self, telemetry: TelemetryPayload) -> Optional[str]:
        """Store telemetry data in S3"""
        if not self.s3_client:
            logger.error("S3 client not initialized")
            return None

        try:
            # Generate S3 key with partitioning
            timestamp = datetime.fromisoformat(telemetry.timestamp.replace('Z', '+00:00'))
            s3_key = (
                f"raw-telemetry/"
                f"year={timestamp.year}/"
                f"month={timestamp.month:02d}/"
                f"day={timestamp.day:02d}/"
                f"data_type={telemetry.data_type}/"
                f"{telemetry.edge_id}_{timestamp.isoformat()}.json"
            )

            # Upload to S3
            with s3_upload_duration.labels(bucket=self.bucket_name).time():
                self.s3_client.put_object(
                    Bucket=self.bucket_name,
                    Key=s3_key,
                    Body=json.dumps(telemetry.model_dump(), indent=2),
                    ContentType='application/json',
                    Metadata={
                        'edge_id': telemetry.edge_id,
                        'data_type': telemetry.data_type,
                        'collection_time': telemetry.metadata.collection_time
                    }
                )

            logger.info(f"Stored telemetry in S3: {s3_key}")
            return s3_key

        except ClientError as e:
            logger.error(f"S3 upload error: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error storing telemetry: {e}")
            return None


# Global storage instance
storage: Optional[S3Storage] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    global storage

    # Startup
    bucket_name = os.environ.get("S3_BUCKET_NAME", "f1-telemetry-raw")
    region = os.environ.get("AWS_REGION", "us-east-1")
    storage = S3Storage(bucket_name=bucket_name, region=region)

    logger.info("Ingestion service started")

    yield

    # Shutdown
    logger.info("Ingestion service shutting down")


# Initialize FastAPI app
app = FastAPI(
    title="F1 Telemetry Ingestion Service",
    description="Receives and stores F1 telemetry data from edge devices",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0"
    )


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )


@app.post("/api/v1/telemetry", status_code=status.HTTP_202_ACCEPTED)
async def ingest_telemetry(telemetry: TelemetryPayload, request: Request):
    """
    Ingest telemetry data from edge devices
    """
    with telemetry_processing_duration.labels(data_type=telemetry.data_type).time():
        try:
            # Validate edge ID from header
            edge_id_header = request.headers.get("X-Edge-ID")
            if edge_id_header and edge_id_header != telemetry.edge_id:
                logger.warning(
                    f"Edge ID mismatch: header={edge_id_header}, body={telemetry.edge_id}"
                )

            # Store in S3
            s3_key = storage.store_telemetry(telemetry)

            if not s3_key:
                telemetry_requests_total.labels(
                    data_type=telemetry.data_type,
                    status="failed"
                ).inc()
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to store telemetry"
                )

            telemetry_requests_total.labels(
                data_type=telemetry.data_type,
                status="success"
            ).inc()

            return {
                "status": "accepted",
                "s3_key": s3_key,
                "timestamp": datetime.utcnow().isoformat()
            }

        except Exception as e:
            logger.error(f"Error processing telemetry: {e}")
            telemetry_requests_total.labels(
                data_type=telemetry.data_type,
                status="error"
            ).inc()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=str(e)
            )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "F1 Telemetry Ingestion Service",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "metrics": "/metrics",
            "telemetry": "/api/v1/telemetry"
        }
    }


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
