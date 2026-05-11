WITH location_data AS (
    SELECT DISTINCT
        borough,
        incident_zip AS zip_code
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE incident_zip IS NOT NULL
        AND borough IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS location_key,
    borough,
    zip_code
FROM location_data