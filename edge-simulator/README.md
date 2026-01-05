# F1 Telemetry Edge Simulator

Simulates trackside telemetry collection and transmission to cloud infrastructure.

## Features

- Pulls real F1 data from Ergast API (races, lap times, pit stops, qualifying)
- Simulates network conditions (latency, packet loss)
- Enriches data with edge metadata
- Resilient transmission with retry logic
- Configurable via environment variables

## Usage

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run with default settings
python main.py

# Run with custom endpoint
CLOUD_ENDPOINT=http://your-ingestion-service/api/v1/telemetry python main.py
```

### Docker

```bash
# Build image
docker build -t f1-edge-simulator:latest .

# Run container
docker run -e CLOUD_ENDPOINT=http://ingestion-service:8000/api/v1/telemetry \
           -e COLLECTION_INTERVAL=60 \
           -e SIMULATE_LATENCY=true \
           f1-edge-simulator:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLOUD_ENDPOINT` | `http://localhost:8000/api/v1/telemetry` | Cloud ingestion endpoint |
| `COLLECTION_INTERVAL` | `60` | Seconds between collection cycles |
| `SIMULATE_LATENCY` | `true` | Enable network latency simulation |
| `SIMULATE_PACKET_LOSS` | `false` | Enable packet loss simulation |
| `PACKET_LOSS_RATE` | `0.05` | Packet loss rate (0.0-1.0) |
| `EDGE_ID` | `edge-simulator-001` | Unique edge device identifier |

## Data Types Collected

- **race_results**: Race finishing positions and points
- **lap_times**: Individual lap times for all drivers
- **pit_stops**: Pit stop timings and durations
- **qualifying**: Qualifying session results
