-- Zipcode dimension shared by both sources

WITH complaints_zip AS (
    SELECT DISTINCT
        borough,
        incident_zip AS zipcode
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE incident_zip IS NOT NULL
        AND borough IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')
),
licensing_zip AS (
    SELECT DISTINCT
        owner_zipcode AS zipcode,
        NULL AS borough
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE owner_zipcode IS NOT NULL
),
all_zipcodes AS (
    SELECT
        lz.zipcode,
        COALESCE(cz.borough, 'Unknown') AS borough
    FROM licensing_zip lz
    LEFT JOIN complaints_zip cz
        ON lz.zipcode = cz.zipcode
    UNION DISTINCT
    SELECT
        zipcode,
        borough
    FROM complaints_zip
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['borough', 'zipcode']) }} AS zipcode_key,
    zipcode,
    borough
FROM all_zipcodes