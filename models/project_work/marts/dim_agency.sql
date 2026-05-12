-- Agency dimension (Sourced only from 311 data)
WITH agencies AS (
    SELECT DISTINCT
        agency,
        agency_name
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE agency IS NOT NULL
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['agency']) }} AS agency_key,
    agency,
    agency_name
FROM agencies