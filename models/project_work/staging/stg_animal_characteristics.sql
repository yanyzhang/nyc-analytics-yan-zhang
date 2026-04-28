-- Clean and standardize Animal Characteristics data
WITH source AS (
    SELECT * FROM {{ source('group5_raw', 'Dim_Animal_CHaracteristics') }}
),

cleaned AS (
    SELECT
        -- Standardize the breed name to ensure perfect joins with the licensing data
        TRIM(breed_name) AS breed_name,
        
        -- Standardize categorical data
        UPPER(TRIM(size_category)) AS size_category,
        TRIM(temperament) AS temperament,
        TRIM(source_note) AS source_note,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at
        
    FROM source
    WHERE breed_name IS NOT NULL
)

-- Deduplicate to ensure exactly one row per breed mapping
SELECT * FROM cleaned
QUALIFY ROW_NUMBER() OVER (PARTITION BY breed_name ORDER BY breed_name) = 1