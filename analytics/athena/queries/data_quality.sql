-- Data quality checks
-- Identify missing data or anomalies

WITH data_summary AS (
  SELECT
    date_trunc('day', from_iso8601_timestamp(timestamp)) as day,
    data_type,
    edge_id,
    COUNT(*) as record_count,
    COUNT(DISTINCT date_trunc('hour', from_iso8601_timestamp(timestamp))) as hours_with_data
  FROM f1_telemetry.raw_telemetry
  WHERE year = 2025
    AND month = 12
  GROUP BY
    date_trunc('day', from_iso8601_timestamp(timestamp)),
    data_type,
    edge_id
)
SELECT
  day,
  data_type,
  edge_id,
  record_count,
  hours_with_data,
  CASE
    WHEN hours_with_data < 20 THEN 'WARNING: Gaps in data'
    WHEN record_count < 10 THEN 'WARNING: Low record count'
    ELSE 'OK'
  END as status
FROM data_summary
ORDER BY day DESC, data_type, edge_id;
