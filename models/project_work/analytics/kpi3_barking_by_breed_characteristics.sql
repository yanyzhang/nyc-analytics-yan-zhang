-- KPI 3: Barking/Noise Complaints by Dog Characteristics per ZIP (Size & Temperament)
-- Purpose: To analyze if certain dog traits (like being a large breed or having a specific
-- temperament) correlate with higher rates of barking complaints in NYC neighborhoods.


-- create a table to store these results for our BI dashboard

WITH dog_characteristics AS (
    -- 1. get the basic counts of every dog size and temperament in each ZIP code
    SELECT 
        dz.zipcode AS zip_code,
        dac.size_category,
        dac.temperament,
        COUNT(*) AS breed_count --how many
      -- join from fact_dog_licensing, dim_zipcode, dim_animal_characteristics
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_animal_characteristics` dac
        ON f.animal_characteristics_key = dac.animal_characteristics_key
    GROUP BY 1, 2, 3
),

dominant_size AS (
   --2. find the most common dog size (the "Dominant Size") for each ZIP code
    SELECT
        zip_code,
        size_category AS dominant_size,
        ROW_NUMBER() OVER (PARTITION BY zip_code ORDER BY total_count DESC) AS rank_size,
        total_count,
        SUM(total_count) OVER (PARTITION BY zip_code) AS known_total
    FROM (
      -- exclude 'Unknown' to make sure our "Dominant" trait is actually meaningful
        SELECT
            zip_code,
            size_category,
            SUM(breed_count) AS total_count
        FROM dog_characteristics
        WHERE UPPER(size_category) NOT IN ('UNKNOWN', 'VARIED')
        GROUP BY zip_code, size_category
    )
),

dominant_temperament AS (
   -- 3. find the most common dog temperament (the "Dominant Temperament") per ZIP
    SELECT
        zip_code,
        temperament AS dominant_temperament,
        -- rank them to find the #1 most common temperament
        ROW_NUMBER() OVER (PARTITION BY zip_code ORDER BY total_count DESC) AS rank_temp
    FROM (
      -- exclude 'Unknown' and 'Varied' profiles here as well 
        SELECT
            zip_code,
            temperament,
            SUM(breed_count) AS total_count
        FROM dog_characteristics
        WHERE UPPER(temperament) NOT IN ('UNKNOWN', 'VARIED')
        GROUP BY zip_code, temperament
    )
),

total_dogs_per_zip AS (
   -- 4. count the total licensed dogs in each ZIP to use as our denominator
    SELECT 
        dz.zipcode AS zip_code,
        COUNT(*) AS total_licensed_dogs
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
   -- limit analysis to the 5 official NYC Boroughs since there were few that were outside of nyc
    WHERE dz.borough IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')
    GROUP BY 1
),

barking_complaints AS (
   -- 5. count only the specific "Barking Dog" complaints from the 311 data
    SELECT 
        dl.zip_code,
        COUNT(*) AS total_barking_complaints
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_311_dog_complaints` c
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_location` dl 
        ON c.location_key = dl.location_key
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_complaint_type` dct
        ON c.complaint_type_key = dct.complaint_type_key
   -- use an exact match for the standardized complaint type in our dimension table
    WHERE dct.complaint_type = 'Noise'
        AND dct.descriptor = 'Noise, Barking Dog (NR5)'
    GROUP BY 1
),

final_analysis AS (
    -- 6. Combine all the previous steps to calculate the final KPI rate
    SELECT 
        CAST(td.zip_code AS STRING) AS zip_code,
        ds.dominant_size,
        dt.dominant_temperament,
        td.total_licensed_dogs,
        -- showing 0 instead of NULL value if a ZIP code has no complaints
        COALESCE(bc.total_barking_complaints, 0) AS total_barking_complaints,
        -- calculate rate per 100 dogs
        ROUND(
            (COALESCE(bc.total_barking_complaints, 0) / NULLIF(td.total_licensed_dogs, 0)) * 100, 
            3
        ) AS barking_rate_per_100_dogs
    FROM total_dogs_per_zip td
    -- Use LEFT JOIN to ensure we don't lose ZIPs that lack specific traits or complaints
    LEFT JOIN dominant_size ds 
        ON td.zip_code = ds.zip_code 
        AND ds.rank_size = 1
        AND ds.total_count >= 0.1 * td.total_licensed_dogs  -- dominant size at least 10% of total dogs
    LEFT JOIN dominant_temperament dt 
        ON td.zip_code = dt.zip_code AND dt.rank_temp = 1
    LEFT JOIN barking_complaints bc 
        ON td.zip_code = bc.zip_code
   -- only look at ZIP codes with at least 10 licensed dogs to avoid misleading percentages from tiny sample sizes
    WHERE td.total_licensed_dogs >= 10
)

SELECT * FROM final_analysis
ORDER BY barking_rate_per_100_dogs DESC