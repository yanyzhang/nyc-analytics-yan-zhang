 -- Quick test to verify source connection works
SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
FROM {{ source('group5_raw', 'source_311nyc_service_requests') }}
LIMIT 10