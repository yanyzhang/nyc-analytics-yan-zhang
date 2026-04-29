-- Gender and Birth Year dimension

WITH demographic_data AS (
    SELECT DISTINCT
        animal_gender,
        CAST(animal_birth_year AS STRING) AS animal_birth_year
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE animal_gender IS NOT NULL 
       OR animal_birth_year IS NOT NULL
),

gender_birth_year_dimension AS (
    SELECT
        -- Generate surrogate key combining gender and birth year
        {{ dbt_utils.generate_surrogate_key(['animal_gender', 'animal_birth_year']) }} AS gender_birth_year_key,
        
        animal_gender,
        animal_birth_year
        
    FROM demographic_data
)

SELECT * FROM gender_birth_year_dimension