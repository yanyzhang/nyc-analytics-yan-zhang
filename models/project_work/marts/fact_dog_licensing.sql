-- Fact table for NYC Dog Licensing
WITH licensing_data AS (
    SELECT 
        *,
        'Department of Health and Mental Hygiene' AS agency_name
    FROM {{ ref('stg_nyc_dog_licensing') }}
),

dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),

dim_animal AS (
    SELECT * FROM {{ ref('dim_animal_characteristics') }}
),

dim_gender_birth AS (
    SELECT * FROM {{ ref('dim_gender_and_birth_year') }}
),

dim_zip AS (
    SELECT * FROM {{ ref('dim_zipcode') }}
),

dim_agency AS (
    SELECT * FROM {{ ref('dim_agency') }}
),

fact_licensing AS (
    SELECT
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key([
            'l.animal_name',
            'l.breed_name',
            'l.owner_zipcode',
            'l.license_issued_date'
        ]) }} AS licensing_event_key,

        -- Natural key
        CAST(l.animal_name AS STRING) AS animal_name,

        -- Event timestamps
        CAST(l.license_issued_date AS TIMESTAMP) AS license_issued_timestamp,
        CAST(l.license_expired_date AS TIMESTAMP) AS license_expired_timestamp,

        -- Dimension keys
        d_issued.date_key AS license_issued_date_key,
        d_expired.date_key AS license_expired_date_key,
        d_animal.animal_characteristics_key AS animal_characteristics_key,
        d_gen_birth.gender_birth_year_key AS gender_birth_year_key,
        d_zip.zipcode_key AS zipcode_key,
        d_ag.agency_key AS agency_key,

        -- Degenerate dimensions
        CAST(l.extract_year AS STRING) AS extract_year

    FROM licensing_data l

    LEFT JOIN dim_date d_issued
        ON CAST(l.license_issued_date AS DATE) = d_issued.full_date
    LEFT JOIN dim_date d_expired
        ON CAST(l.license_expired_date AS DATE) = d_expired.full_date
    LEFT JOIN dim_animal d_animal
        ON l.breed_name = d_animal.breed_name
    LEFT JOIN dim_gender_birth d_gen_birth
        ON l.animal_gender = d_gen_birth.animal_gender
        AND CAST(l.animal_birth_year AS STRING) = CAST(d_gen_birth.animal_birth_year AS STRING)
    LEFT JOIN dim_zip d_zip
        ON l.owner_zipcode = d_zip.zipcode
        
 
    LEFT JOIN dim_agency d_ag
        ON l.agency_name = d_ag.agency_name
)

SELECT * FROM fact_licensing