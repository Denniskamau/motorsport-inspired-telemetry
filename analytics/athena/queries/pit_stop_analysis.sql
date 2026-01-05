-- Analyze pit stop data
-- This query calculates pit stop statistics

WITH pit_stop_data AS (
  SELECT
    timestamp,
    edge_id,
    data_type,
    year,
    month,
    day
  FROM f1_telemetry.raw_telemetry
  WHERE data_type = 'pit_stops'
    AND year = 2025
  LIMIT 100
)
SELECT
  date_format(from_iso8601_timestamp(timestamp), '%Y-%m-%d') as race_date,
  edge_id,
  COUNT(*) as pit_stop_records,
  MIN(timestamp) as first_collection,
  MAX(timestamp) as last_collection,
  date_diff('second',
    from_iso8601_timestamp(MIN(timestamp)),
    from_iso8601_timestamp(MAX(timestamp))
  ) as collection_duration_seconds
FROM pit_stop_data
GROUP BY
  date_format(from_iso8601_timestamp(timestamp), '%Y-%m-%d'),
  edge_id
ORDER BY race_date DESC;
