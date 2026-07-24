-- Dimension table: Payment Types

SELECT 1 AS payment_type_id, 'Credit card' AS payment_description
UNION ALL
SELECT 2 AS payment_type_id, 'Cash' AS payment_description
UNION ALL
SELECT 3 AS payment_type_id, 'No charge' AS payment_description
UNION ALL
SELECT 4 AS payment_type_id, 'Dispute' AS payment_description
UNION ALL
SELECT 5 AS payment_type_id, 'Unknown' AS payment_description
UNION ALL
SELECT 6 AS payment_type_id, 'Voided trip' AS payment_description
