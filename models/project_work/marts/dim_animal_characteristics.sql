-- Animal Characteristics dimension

WITH characteristics_data AS (
    SELECT DISTINCT
        breed_name,
        size_category,
        temperament
    FROM {{ ref('stg_animal_characteristics') }}
    WHERE breed_name IS NOT NULL
),

animal_characteristics_dimension AS (
    SELECT
        -- Generate surrogate key based on the breed name
        {{ dbt_utils.generate_surrogate_key(['breed_name']) }} AS animal_characteristics_key,
        
        breed_name,
        size_category,
        temperament
        
    FROM characteristics_data
)

SELECT * FROM animal_characteristics_dimension