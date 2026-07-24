-- Fact Table: Enriched Trips Gold Layer

WITH trips AS (
    SELECT * FROM {{ ref('stg_nyc_trips') }}
),

vendors AS (
    SELECT * FROM {{ ref('dim_vendors') }}
),

payments AS (
    SELECT * FROM {{ ref('dim_payment_types') }}
)

SELECT
    t.trip_id,
    t.vendor_id,
    v.vendor_name,
    t.pickup_datetime,
    t.dropoff_datetime,
    t.passenger_count,
    t.trip_distance,
    t.payment_type_id,
    p.payment_description,
    t.fare_amount,
    t.tip_amount,
    t.tolls_amount,
    t.total_amount,
    t.trip_duration_minutes,
    t.tip_percentage,
    t.pickup_location_id,
    t.dropoff_location_id,
    t.trip_year,
    t.trip_month
FROM trips t
LEFT JOIN vendors v ON t.vendor_id = v.vendor_id
LEFT JOIN payments p ON t.payment_type_id = p.payment_type_id
