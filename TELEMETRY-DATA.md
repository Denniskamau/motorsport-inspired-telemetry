# 🏎️ F1 Telemetry Data Reference

## Data Types Being Collected

The platform now collects **7 comprehensive data types** from the 2024 Bahrain Grand Prix:

### 1. 🏁 Race Results
**File**: `2024-bahrain-results.json`
**Update Frequency**: Every 30s
**Data Points**:
- Driver positions (1st-20th)
- Total race time
- Gap to winner
- Grid position
- Laps completed
- Status (Finished/DNF/+N Laps)
- Points scored
- Constructor information
- Driver details (name, nationality, number)

**Race-Critical Info**:
- Who won the race
- Final positions
- Race pace comparison
- Grid vs finish position changes

---

### 2. ⛽ Pit Stops
**File**: `2024-bahrain-pitstops.json`
**Update Frequency**: Every 30s
**Data Points**:
- **10 pit stops** across top 5 drivers
- Stop duration (2.3-2.7 seconds)
- Lap number of stop
- Stop sequence (1st stop, 2nd stop)
- **Tire compound** (SOFT/MEDIUM/HARD)
- **From compound** (what they changed from)
- Time of pit stop

**Race-Critical Info**:
- Pit strategy (1-stop vs 2-stop)
- Tire degradation analysis
- Pit crew performance (stop duration)
- Undercut/overcut opportunities
- Tire compound choices

---

### 3. 🏆 Qualifying Results
**File**: `2024-bahrain-qualifying.json`
**Update Frequency**: Every 30s
**Data Points**:
- Grid positions 1-2 (VER, PER)
- Q3 lap times
- Driver information
- Circuit data

**Race-Critical Info**:
- Starting grid
- Qualifying pace
- Team battle (RB domination)

---

### 4. ⏱️ Lap Times
**File**: `2024-bahrain-laps.json`
**Update Frequency**: Every 30s
**Data Points**:
- **7 lap snapshots** (lap 1, 10, 20, 30, 40, 50, 57)
- Top 5 drivers per lap
- Position on track
- Lap time
- Lap-by-lap progression

**Race-Critical Info**:
- Race pace evolution
- Tire degradation curves
- Position changes
- Gap management
- Safety car detection (consistent lap times)

---

### 5. 🏎️ Fastest Laps
**File**: `2024-bahrain-fastest-laps.json`
**Update Frequency**: Every 30s
**Data Points**:
- Top 3 fastest laps
- Lap number when set
- Average speed (km/h)
- Driver who set it

**Race-Critical Info**:
- Ultimate pace
- Fresh tire performance
- Bonus point contention
- Speed trap data

---

### 6. 👤 Driver Standings
**File**: `2024-bahrain-driver-standings.json`
**Update Frequency**: Every 30s
**Data Points**:
- Championship position (1-5)
- Points total
- Wins
- Team affiliation

**Race-Critical Info**:
- Championship battle
- Points gap
- Win progression
- Team dynamics

---

### 7. 🏁 Constructor Standings
**File**: `2024-bahrain-constructor-standings.json`
**Update Frequency**: Every 30s
**Data Points**:
- Team championship position (1-5)
- Combined points
- Wins
- Team nationality

**Race-Critical Info**:
- Team battle (Red Bull 43pts vs Ferrari 27pts)
- Constructor championship progression
- Development race

---

## Data Flow Architecture

```
┌─────────────────────────────────┐
│  Edge Simulator (Replay Mode)  │
│                                 │
│  Cycle Every 30s:               │
│  1. Race Results    (2s delay)  │
│  2. Pit Stops       (2s delay)  │
│  3. Qualifying      (2s delay)  │
│  4. Lap Times       (2s delay)  │
│  5. Fastest Laps    (2s delay)  │
│  6. Driver Standings (2s delay) │
│  7. Constructor Standings       │
└────────────┬────────────────────┘
             │ HTTP POST
             │ /api/v1/telemetry
             ▼
┌─────────────────────────────────┐
│  Ingestion Service (FastAPI)   │
│                                 │
│  - Validates payload            │
│  - Enriches with metadata       │
│  - Stores to MinIO/S3           │
│  - Exposes Prometheus metrics   │
└────────────┬────────────────────┘
             │
             ├──► MinIO (Partitioned Storage)
             │    year=2024/season=2024/
             │    race=bahrain/data_type=X/
             │
             └──► Prometheus (Metrics)
                  telemetry_requests_total
                  {data_type, status}
```

## Prometheus Metrics

### Primary Metric
```promql
telemetry_requests_total{data_type, status, namespace, pod}
```

**Labels**:
- `data_type`: race_results, pit_stops, qualifying, lap_times, fastest_laps, driver_standings, constructor_standings
- `status`: success, error
- `namespace`: default
- `pod`: ingestion-service-xxx

### Example Queries

**Total race results received**:
```promql
sum(increase(telemetry_requests_total{data_type="race_results"}[5m]))
```

**Pit stop events per minute**:
```promql
sum(rate(telemetry_requests_total{data_type="pit_stops"}[1m]))
```

**Success rate by data type**:
```promql
sum(rate(telemetry_requests_total{status="success"}[5m])) by (data_type)
/ sum(rate(telemetry_requests_total[5m])) by (data_type) * 100
```

**Data type distribution (last hour)**:
```promql
sum(increase(telemetry_requests_total[1h])) by (data_type)
```

**Fastest growing data type**:
```promql
topk(1, rate(telemetry_requests_total[5m]) by (data_type))
```

## Grafana Dashboard Panels

The enhanced dashboard includes:

### Race Operations (Top Section)
1. **Race Results Table** - Final positions, times, gaps
2. **Driver Championship Standings** - Live points, wins
3. **Pit Stop Duration** - Bar gauge showing stop performance
4. **Pit Stop Timeline** - When stops happened (lap number)
5. **Fastest Laps** - Top performers with times
6. **Qualifying Grid** - Starting positions
7. **Constructor Championship** - Team battle pie chart

### Race Analysis (Middle Section)
8. **Lap Time Progression** - Line graph showing pace evolution
9. **Telemetry Ingestion Rate** - Data flow by type (stacked)

### Operations Monitoring (Bottom Section)
10. **Total Telemetry Volume** - Events received (last hour)
11. **Success Rate Gauge** - Ingestion health
12. **Data Type Distribution** - Pie chart of data mix
13. **Edge Devices Active** - Simulator count
14. **Processing Latency** - p95/p50 performance
15. **Storage Upload Performance** - MinIO write times
16. **Race Information Panel** - Static context

## Storage Structure in MinIO/S3

```
f1-telemetry-raw/
├── year=2025/
│   └── month=01/
│       └── day=01/
│           ├── data_type=race_results/
│           │   └── edge-simulator-xxx_timestamp.json
│           ├── data_type=pit_stops/
│           │   └── edge-simulator-xxx_timestamp.json
│           ├── data_type=qualifying/
│           ├── data_type=lap_times/
│           ├── data_type=fastest_laps/
│           ├── data_type=driver_standings/
│           └── data_type=constructor_standings/
```

**Partitioning Strategy**:
- **By date**: Easy time-based queries
- **By data type**: Filter specific telemetry
- **Hive-compatible**: Ready for AWS Glue/Athena

## Athena Query Examples

**Query pit stop performance**:
```sql
SELECT
  json_extract_scalar(payload, '$.MRData.RaceTable.Races[0].PitStops[0].driverId') as driver,
  json_extract_scalar(payload, '$.MRData.RaceTable.Races[0].PitStops[0].duration') as duration,
  json_extract_scalar(payload, '$.MRData.RaceTable.Races[0].PitStops[0].tyreCompound') as tire
FROM f1_telemetry_raw
WHERE data_type = 'pit_stops'
ORDER BY duration ASC
LIMIT 10;
```

**Analyze tire strategy**:
```sql
SELECT
  driver_id,
  COUNT(*) as pit_stop_count,
  AVG(CAST(duration AS DOUBLE)) as avg_duration
FROM f1_pit_stops
GROUP BY driver_id;
```

## Race-Useful Information Summary

This telemetry data enables real-world F1 race analysis:

### Strategy Analysis
- ✅ Pit stop timing and duration
- ✅ Tire compound choices
- ✅ Stop sequence (1-stop vs 2-stop)
- ✅ Undercut/overcut opportunities

### Performance Analysis
- ✅ Lap time progression (tire deg)
- ✅ Fastest laps and ultimate pace
- ✅ Quali vs race pace comparison
- ✅ Gap to leader tracking

### Championship Context
- ✅ Points scoring
- ✅ Driver standings progression
- ✅ Constructor battle
- ✅ Win statistics

### Operational Insights
- ✅ Grid position changes
- ✅ DNF tracking
- ✅ Race completion rate
- ✅ Position gained/lost from grid

## For Toyota Gazoo Racing Interview

**Talking Points**:
1. "I've replicated actual race-critical telemetry from the 2024 Bahrain GP"
2. "The system captures 7 data types that teams use for strategy decisions"
3. "Pit stop data includes tire compounds - crucial for strategy analysis"
4. "Lap time progression shows tire degradation patterns"
5. "This mirrors the edge-to-cloud flow Toyota uses trackside → Cologne"
6. "Data is partitioned for efficient querying - race engineers need instant access"
7. "Real-time ingestion with sub-second latency - race decisions happen in seconds"

---

**Live Demo URL** (after Pi deployment): https://f1-telemetry.yourname.com

The Grafana dashboard will show all 7 data types flowing in real-time, giving recruiters instant insight into your understanding of motorsport operations.
