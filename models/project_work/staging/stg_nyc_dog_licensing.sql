-- Clean and standardize NYC Dog Licensing data
WITH source AS (
    SELECT * FROM {{ source('group5_raw', 'source_nyc_dog_licensing') }}
),

cleaned AS (
    SELECT
        -- Standardize text fields
        TRIM(animalname) AS animal_name,
        UPPER(TRIM(animalgender)) AS animal_gender,
        

        -- Clean messy user-input breeds using keyword matching
        CASE 
-- 1. The Core Mixes & Crosses (Catches misspellings like 'Doole')
            WHEN UPPER(TRIM(breedname)) LIKE '%MIX%' OR UPPER(TRIM(breedname)) LIKE '%CROSS%' OR UPPER(TRIM(breedname)) LIKE '%MUTT%' THEN 'MIXED/OTHER'
            WHEN UPPER(TRIM(breedname)) LIKE '%POODLE%' OR UPPER(TRIM(breedname)) LIKE '%DOODLE%' OR UPPER(TRIM(breedname)) LIKE '%DOOLE%' THEN 'POODLE'
            WHEN UPPER(TRIM(breedname)) LIKE '%RETREIVER%' THEN 'RETRIEVER'
            WHEN UPPER(TRIM(breedname)) LIKE '%STAFFORDSHIE%' OR UPPER(TRIM(breedname)) LIKE '%STAFF%' THEN 'STAFFORDSHIRE TERRIER'
            
            -- 2. Small & Toy Breeds (Catches all those Maltepoos, Shorkies, etc.)
            WHEN UPPER(TRIM(breedname)) LIKE '%MALT%' THEN 'MALTESE'
            WHEN UPPER(TRIM(breedname)) LIKE '%SHIH%' THEN 'SHIH TZU'
            WHEN UPPER(TRIM(breedname)) LIKE '%YORK%' THEN 'YORKSHIRE TERRIER'
            WHEN UPPER(TRIM(breedname)) LIKE '%CHIH%' THEN 'CHIHUAHUA'
            WHEN UPPER(TRIM(breedname)) LIKE '%DACHSHUND%' OR UPPER(TRIM(breedname)) LIKE '%DOXIE%' THEN 'DACHSHUND'
            WHEN UPPER(TRIM(breedname)) LIKE '%CORGI%' THEN 'CORGI'
            WHEN UPPER(TRIM(breedname)) LIKE '%PUG%' THEN 'PUG'
            
            -- 3. Medium / Large / Working Breeds
            WHEN UPPER(TRIM(breedname)) LIKE '%TERRIER%' THEN 'TERRIER'
            WHEN UPPER(TRIM(breedname)) LIKE '%RETRIEVER%' OR UPPER(TRIM(breedname)) LIKE '%LAB%' THEN 'RETRIEVER'
            WHEN UPPER(TRIM(breedname)) LIKE '%SHEPHERD%' THEN 'SHEPHERD'
            WHEN UPPER(TRIM(breedname)) LIKE '%BULL%' OR UPPER(TRIM(breedname)) LIKE '%PIT%' THEN 'BULLDOG / PIT BULL'
            WHEN UPPER(TRIM(breedname)) LIKE '%SCHNAUZER%' THEN 'SCHNAUZER'
            WHEN UPPER(TRIM(breedname)) LIKE '%SPANIEL%' THEN 'SPANIEL'
            WHEN UPPER(TRIM(breedname)) LIKE '%HOUND%' THEN 'HOUND'
            WHEN UPPER(TRIM(breedname)) LIKE '%BEAGLE%' THEN 'BEAGLE'
            WHEN UPPER(TRIM(breedname)) LIKE '%COLLIE%' THEN 'COLLIE'
            WHEN UPPER(TRIM(breedname)) LIKE '%MASTIFF%' THEN 'MASTIFF'
            WHEN UPPER(TRIM(breedname)) LIKE '%HUSKY%' THEN 'HUSKY'
            WHEN UPPER(TRIM(breedname)) LIKE '%BERNARD%' THEN 'SAINT BERNARD'
            -- Catch Poodle mixes not using "Doodle"
            WHEN UPPER(TRIM(breedname)) LIKE '%POO%' THEN 'POODLE'
            
            -- Catch specific abbreviations and unmapped working breeds
            WHEN UPPER(TRIM(breedname)) LIKE '%WESTIE%' THEN 'WEST HIGHLAND WHITE TERRIER'
            WHEN UPPER(TRIM(breedname)) LIKE '%CATTLE%' THEN 'CATTLEDOG'
            WHEN UPPER(TRIM(breedname)) LIKE '%PORTUGESE%' THEN 'PORTUGUESE WATER DOG'

            -- If it doesn't match any of the above, pass the exact string through
            ELSE UPPER(TRIM(breedname))
        END AS breed_name,

        -- Convert years to integer safely 
        SAFE_CAST(animalbirth AS INTEGER) AS animal_birth_year,

        -- Location - clean zip code 
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
        
        -- Metadata safely 
        SAFE_CAST(extract_year AS INTEGER) AS extract_year,
        CURRENT_TIMESTAMP() AS _stg_loaded_at
        
    FROM source
    WHERE zipcode IS NOT NULL
      AND licenseissueddate IS NOT NULL
)

-- Remove exact duplicate rows since there is no primary key
SELECT DISTINCT * FROM cleaned