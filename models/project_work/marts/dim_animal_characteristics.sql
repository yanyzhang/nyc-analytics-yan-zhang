-- Animal Characteristics dimension
-- Revised to guarantee every breed in the licensing data is accounted for

WITH characteristics_mapping AS (
    -- The predefined characteristics mapping
    SELECT DISTINCT
        breed_name,
        size_category,
        temperament
    FROM {{ ref('stg_animal_characteristics') }}
    WHERE breed_name IS NOT NULL
),

licensing_breeds AS (
    -- All unique breeds actually present in the licensing data
    SELECT DISTINCT
        breed_name
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE breed_name IS NOT NULL
),

combined_breeds AS (
    -- Step 1: Ensure all licensing breeds are included, attach characteristics if we have them
    SELECT 
        l.breed_name,
        COALESCE(c.size_category, 'Unknown') AS size_category,
        COALESCE(c.temperament, 'Unknown') AS temperament
    FROM licensing_breeds l
    LEFT JOIN characteristics_mapping c
        ON l.breed_name = c.breed_name
        
    UNION DISTINCT
    
    -- Step 2: Add any leftover breeds from the mapping table that haven't appeared in licensing yet
    SELECT 
        breed_name,
        size_category,
        temperament
    FROM characteristics_mapping
),

animal_characteristics_dimension AS (
    SELECT
        -- Generate surrogate key based on the breed name
        {{ dbt_utils.generate_surrogate_key(['breed_name']) }} AS animal_characteristics_key,
        
        breed_name,
        size_category,
        temperament
        
    FROM combined_breeds
)

SELECT * FROM animal_characteristics_dimension