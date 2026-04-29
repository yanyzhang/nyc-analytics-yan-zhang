-- Zipcode dimension shared by both sources
WITH all_locations AS (
    -- Get locations from 311 requests
    SELECT DISTINCT
        borough,
        incident_zip AS zip_code
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE incident_zip IS NOT NULL

    UNION DISTINCT

    -- Get locations from dog licensing
    SELECT DISTINCT
        'Unknown' AS borough, -- Dog licensing data lacks a borough column
        owner_zipcode AS zip_code
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE owner_zipcode IS NOT NULL
),

zipcode_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS zipcode_key,
        zip_code,
        borough
    FROM all_locations
)

SELECT * FROM zipcode_dimension