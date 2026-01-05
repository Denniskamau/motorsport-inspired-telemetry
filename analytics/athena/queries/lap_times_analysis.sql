-- Analyze lap times data
-- This query extracts lap times and calculates statistics

WITH lap_data AS (
  SELECT
    timestamp,
    edge_id,
    data_type,
    year,
    month,
    day
  FROM f1_telemetry.raw_telemetry
  WHERE data_type = 'lap_times'
    AND year = 2025
  LIMIT 100
)
SELECT
  date_format(from_iso8601_timestamp(timestamp), '%Y-%m-%d') as race_date,
  edge_id,
  COUNT(*) as total_records,
  MIN(timestamp) as first_collection,
  MAX(timestamp) as last_collection
FROM lap_data
GROUP BY
  date_format(from_iso8601_timestamp(timestamp), '%Y-%m-%d'),
  edge_id
ORDER BY race_date DESC, edge_id;
