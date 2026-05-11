-- Complaint Type dimension (Sourced only from 311 data)
WITH complaint_data AS (
    SELECT DISTINCT
        complaint_type,
        COALESCE(descriptor, 'Unknown') AS descriptor
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE complaint_type IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'complaint_type',
        'descriptor'
    ]) }} AS complaint_type_key,
    complaint_type,
    descriptor
FROM complaint_data