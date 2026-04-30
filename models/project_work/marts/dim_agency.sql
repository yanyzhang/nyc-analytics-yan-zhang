-- Agency dimension (Sourced only from 311 data)

WITH agency_data AS (
    SELECT DISTINCT
        agency_name
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE agency_name IS NOT NULL
),

agency_dimension AS (
    SELECT
        -- Generate surrogate key based on the agency name
        {{ dbt_utils.generate_surrogate_key(['agency_name']) }} AS agency_key,
        
        agency_name
        
    FROM agency_data
)

SELECT * FROM agency_dimension