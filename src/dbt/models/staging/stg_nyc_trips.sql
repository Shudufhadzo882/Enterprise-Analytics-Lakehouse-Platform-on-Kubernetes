-- Staging model: Cleaning & Type Standardisation from Silver S3 Layer

WITH raw_silver AS (
    SELECT
        CAST(vendor_id AS INT) AS vendor_id,
        CAST(pickup_datetime AS TIMESTAMP) AS pickup_datetime,
        CAST(dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,
        CAST(passenger_count AS INT) AS passenger_count,
        CAST(trip_distance AS DOUBLE) AS trip_distance,
        CAST(rate_code_id AS INT) AS rate_code_id,
        CAST(payment_type AS INT) AS payment_type_id,
        CAST(fare_amount AS DOUBLE) AS fare_amount,
        CAST(tip_amount AS DOUBLE) AS tip_amount,
        CAST(tolls_amount AS DOUBLE) AS tolls_amount,
        CAST(total_amount AS DOUBLE) AS total_amount,
        CAST(pickup_location_id AS INT) AS pickup_location_id,
        CAST(dropoff_location_id AS INT) AS dropoff_location_id,
        CAST(trip_duration_minutes AS DOUBLE) AS trip_duration_minutes,
        CAST(tip_percentage AS DOUBLE) AS tip_percentage,
        CAST(year AS INT) AS trip_year,
        CAST(month AS INT) AS trip_month
    FROM {{ source('silver_layer', 'nyc_trips') }}
)

SELECT
    MD5(CONCAT(
        COALESCE(CAST(vendor_id AS VARCHAR), ''),
        COALESCE(CAST(pickup_datetime AS VARCHAR), ''),
        COALESCE(CAST(pickup_location_id AS VARCHAR), '')
    )) AS trip_id,
    *
FROM raw_silver
WHERE trip_distance > 0
  AND total_amount >= 0
