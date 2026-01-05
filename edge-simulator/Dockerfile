FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Copy cached race data
COPY cache-data /app/cache-data

# Set environment variables (defaults)
ENV CLOUD_ENDPOINT=http://localhost:8000/api/v1/telemetry
ENV COLLECTION_INTERVAL=60
ENV SIMULATE_LATENCY=true
ENV SIMULATE_PACKET_LOSS=false
ENV PACKET_LOSS_RATE=0.05
ENV EDGE_ID=edge-simulator-001

# Run the application
CMD ["python", "-u", "main.py"]
