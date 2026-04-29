-- Fact Table for Dog Licensing

WITH licensing_data AS (
    SELECT * FROM {{ ref('stg_nyc_dog_licensing') }}
),

final_fact AS (
    SELECT
        -- Generate a unique Licensing_ID since the raw data lacks a primary key
        {{ dbt_utils.generate_surrogate_key([
            'animal_name', 
            'breed_name', 
            'owner_zipcode', 
            'license_issued_date'
        ]) }} AS licensing_id,

        animal_name,

        -- ---------------------------------------------------------
        -- FOREIGN KEYS linking to your dimensions
        -- ---------------------------------------------------------
        {{ dbt_utils.generate_surrogate_key(['breed_name']) }} AS animal_characteristics_key,
        
        {{ dbt_utils.generate_surrogate_key(['animal_gender', 'CAST(animal_birth_year AS STRING)']) }} AS gender_birth_year_key,
        
        {{ dbt_utils.generate_surrogate_key(["'Unknown'", 'owner_zipcode']) }} AS zipcode_key,
        
        {{ dbt_utils.generate_surrogate_key(["'Department of Health and Mental Hygiene'"]) }} AS agency_key,
        
        -- Integer Date Keys (YYYYMMDD)
        CAST(FORMAT_DATE('%Y%m%d', license_issued_date) AS INT64) AS license_issued_date_key,
        CAST(FORMAT_DATE('%Y%m%d', license_expired_date) AS INT64) AS license_expired_date_key,

        -- ---------------------------------------------------------
        -- ATTRIBUTES
        -- ---------------------------------------------------------
        CAST(extract_year AS STRING) AS extract_year
        
    FROM licensing_data
)

SELECT * FROM final_fact