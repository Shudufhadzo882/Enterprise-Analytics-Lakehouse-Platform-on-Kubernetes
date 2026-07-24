-- Gold Analytical Mart: Monthly Revenue & Performance Summary

SELECT
    trip_year,
    trip_month,
    vendor_name,
    COUNT(trip_id) AS total_trips,
    SUM(passenger_count) AS total_passengers,
    ROUND(SUM(trip_distance), 2) AS total_distance_miles,
    ROUND(AVG(trip_distance), 2) AS avg_distance_miles,
    ROUND(SUM(fare_amount), 2) AS total_fare_revenue,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(SUM(total_amount), 2) AS gross_revenue,
    ROUND(AVG(tip_percentage), 2) AS avg_tip_percentage,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_trip_duration_minutes
FROM {{ ref('fct_trips') }}
GROUP BY
    trip_year,
    trip_month,
    vendor_name
ORDER BY
    trip_year DESC,
    trip_month DESC,
    gross_revenue DESC
