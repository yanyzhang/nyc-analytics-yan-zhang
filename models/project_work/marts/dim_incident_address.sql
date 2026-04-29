-- Incident Address dimension (Sourced only from 311 data)

WITH address_data AS (
    SELECT DISTINCT
        incident_address,
        street_name,
        address_type,
        city,
        community_board,
        council_district
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE incident_address IS NOT NULL
),

incident_address_dimension AS (
    SELECT
        -- Generate surrogate key combining all address components to ensure uniqueness
        {{ dbt_utils.generate_surrogate_key([
            'incident_address',
            'street_name',
            'address_type',
            'city',
            'community_board',
            'council_district'
        ]) }} AS incident_address_key,
        
        incident_address,
        street_name,
        address_type,
        city,
        community_board,
        council_district
        
    FROM address_data
)

SELECT * FROM incident_address_dimension