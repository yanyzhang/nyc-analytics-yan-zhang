-- Location Type dimension (Sourced only from 311 data)

WITH location_type_data AS (
    SELECT DISTINCT
        location_type
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE location_type IS NOT NULL
),

location_type_dimension AS (
    SELECT
        -- Generate surrogate key based on the location type
        {{ dbt_utils.generate_surrogate_key(['location_type']) }} AS location_type_key,
        
        location_type
        
    FROM location_type_data
)

SELECT * FROM location_type_dimension