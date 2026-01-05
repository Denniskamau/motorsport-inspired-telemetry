-- Create external table for raw telemetry
-- Run this if Glue crawler doesn't automatically create the table

CREATE EXTERNAL TABLE IF NOT EXISTS f1_telemetry.raw_telemetry (
  timestamp STRING,
  edge_id STRING,
  data_type STRING,
  payload STRUCT<
    MRData: STRUCT<
      xmlns: STRING,
      series: STRING,
      url: STRING,
      limit: STRING,
      offset: STRING,
      total: STRING,
      RaceTable: STRUCT<
        season: STRING,
        round: STRING,
        Races: ARRAY<STRUCT<
          season: STRING,
          round: STRING,
          raceName: STRING,
          Circuit: STRUCT<
            circuitId: STRING,
            circuitName: STRING,
            Location: STRUCT<
              lat: STRING,
              long: STRING,
              locality: STRING,
              country: STRING
            >
          >,
          date: STRING,
          time: STRING
        >>
      >
    >
  >,
  metadata STRUCT<
    collection_time: STRING,
    source: STRING,
    version: STRING
  >
)
PARTITIONED BY (
  year INT,
  month INT,
  day INT,
  data_type_partition STRING
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://f1-telemetry-<ENVIRONMENT>-raw-telemetry/raw-telemetry/'
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.year.type' = 'integer',
  'projection.year.range' = '2024,2030',
  'projection.month.type' = 'integer',
  'projection.month.range' = '1,12',
  'projection.month.digits' = '2',
  'projection.day.type' = 'integer',
  'projection.day.range' = '1,31',
  'projection.day.digits' = '2',
  'projection.data_type_partition.type' = 'enum',
  'projection.data_type_partition.values' = 'lap_times,pit_stops,race_results,qualifying',
  'storage.location.template' = 's3://f1-telemetry-<ENVIRONMENT>-raw-telemetry/raw-telemetry/year=${year}/month=${month}/day=${day}/data_type=${data_type_partition}'
);
