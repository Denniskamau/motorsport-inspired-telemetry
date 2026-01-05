-- Ingestion metrics and monitoring
-- Track data ingestion patterns and identify issues

WITH hourly_ingestion AS (
  SELECT
    date_trunc('hour', from_iso8601_timestamp(timestamp)) as hour,
    data_type,
    edge_id,
    COUNT(*) as records_count
  FROM f1_telemetry.raw_telemetry
  WHERE year = 2025
    AND month = 12
    AND day >= 1
  GROUP BY
    date_trunc('hour', from_iso8601_timestamp(timestamp)),
    data_type,
    edge_id
)
SELECT
  hour,
  data_type,
  edge_id,
  records_count,
  AVG(records_count) OVER (
    PARTITION BY data_type, edge_id
    ORDER BY hour
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) as moving_avg
FROM hourly_ingestion
ORDER BY hour DESC, data_type, edge_id;
