-- Agency dimension shared by both sources

WITH all_agencies AS (
    -- Get agencies from 311 requests
    SELECT DISTINCT
        agency_name
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE agency_name IS NOT NULL

    UNION DISTINCT

    -- Provide the implicit agency for all dog licensing records
    SELECT DISTINCT
        'Department of Health and Mental Hygiene' AS agency_name
    FROM {{ ref('stg_nyc_dog_licensing') }}
),

agency_dimension AS (
    SELECT
        -- Generate surrogate key based on the agency name
        {{ dbt_utils.generate_surrogate_key(['agency_name']) }} AS agency_key,
        
        agency_name
        
    FROM all_agencies
)

SELECT * FROM agency_dimension