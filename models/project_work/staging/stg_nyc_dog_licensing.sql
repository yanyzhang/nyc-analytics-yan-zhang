-- Clean and standardize NYC Dog Licensing data
WITH source AS (
    SELECT * FROM {{ source('group5_raw', 'source_nyc_dog_licensing') }}
),

cleaned AS (
    SELECT
        -- Standardize text fields
        TRIM(animalname) AS animal_name,
        UPPER(TRIM(animalgender)) AS animal_gender,
        TRIM(breedname) AS breed_name,

        -- Convert years to integer safely (handles #VALUE! errors)
        SAFE_CAST(animalbirth AS INTEGER) AS animal_birth_year,

        -- Location - clean zip code using the same rules as the 311 data
        CASE 
            WHEN UPPER(TRIM(CAST(zipcode AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zipcode AS STRING)) = 5 THEN CAST(zipcode AS STRING)
            WHEN LENGTH(CAST(zipcode AS STRING)) = 9 THEN CAST(zipcode AS STRING)
            WHEN LENGTH(CAST(zipcode AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(zipcode AS STRING), r'^\d{5}-\d{4}') THEN CAST(zipcode AS STRING)
            ELSE NULL 
        END AS owner_zipcode,

        -- Standardize dates safely
        SAFE_CAST(licenseissueddate AS TIMESTAMP) AS license_issued_date,
        SAFE_CAST(licenseexpireddate AS TIMESTAMP) AS license_expired_date,
        
        -- Metadata safely (handles #VALUE! errors)
        SAFE_CAST(extract_year AS INTEGER) AS extract_year,
        CURRENT_TIMESTAMP() AS _stg_loaded_at
        
    FROM source
    WHERE zipcode IS NOT NULL
      AND licenseissueddate IS NOT NULL
)

-- Remove exact duplicate rows since there is no primary key
SELECT DISTINCT * FROM cleaned