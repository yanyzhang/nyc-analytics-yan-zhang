-- Zipcode dimension shared by both sources

WITH all_zipcodes AS (
    -- Get zipcodes and boroughs from 311 requests
    SELECT DISTINCT
        borough,
        incident_zip AS zipcode
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE incident_zip IS NOT NULL

    UNION DISTINCT

    -- Get zipcodes from dog licensing
    SELECT DISTINCT
        'Unknown' AS borough, -- Dog licensing data lacks a borough column
        owner_zipcode AS zipcode
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE owner_zipcode IS NOT NULL
),

zipcode_dimension AS (
    SELECT
        -- Generate surrogate key combining borough and zipcode
        {{ dbt_utils.generate_surrogate_key(['borough', 'zipcode']) }} AS zipcode_key,
        zipcode,
        borough
    FROM all_zipcodes
)

SELECT * FROM zipcode_dimension