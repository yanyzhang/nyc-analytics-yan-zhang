--KPI 2: Dog Waste Complaint  by Dog Breed Characteristics - measure the number or rate of dog waste complaints associated with dominant dog breed size or characteristics derived from the licensed dog data.


WITH dog_sizes_by_zip AS (
    -- Count how many dogs of each size exist in each zip code
    SELECT 
        dz.zipcode AS zip_code,
        dac.size_category,
        COUNT(*) AS dog_count
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_animal_characteristics` dac
        ON f.animal_characteristics_key = dac.animal_characteristics_key
    -- We exclude 'Unknown' because we want the dominant *known* physical trait
    WHERE UPPER(dac.size_category) != 'UNKNOWN' 
      AND dac.size_category IS NOT NULL
    GROUP BY dz.zipcode, dac.size_category
),



ranked_sizes_by_zip AS (
    -- Use window function to rank sizes within each zip code based on count
    SELECT 
        zip_code,
        size_category AS dominant_size,
        dog_count,
        ROW_NUMBER() OVER (PARTITION BY zip_code ORDER BY dog_count DESC) AS size_rank
    FROM dog_sizes_by_zip
),

dominant_size_per_zip AS (
    -- Filter to keep ONLY the #1 most common size per zip code
    SELECT 
        zip_code, 
        dominant_size
    FROM ranked_sizes_by_zip
    WHERE size_rank = 1
),


dog_temperaments_by_zip AS (
    --find the most common terperament per zipcode
    SELECT 
        dz.zipcode AS zip_code,
        dac.temperament,
        COUNT(*) AS dog_count
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_animal_characteristics` dac
        ON f.animal_characteristics_key = dac.animal_characteristics_key
    WHERE UPPER(dac.temperament) NOT IN ('UNKNOWN', 'VARIED') --filter out the ones with "unknown" and "varied"
        AND dac.temperament IS NOT NULL
    GROUP BY dz.zipcode, dac.temperament
),

ranked_temperaments_by_zip AS (
    -- rank the temperaments in each zip code based on popularity
    SELECT 
        zip_code,
        temperament AS dominant_temperament,
        dog_count,
        ROW_NUMBER() OVER (PARTITION BY zip_code ORDER BY dog_count DESC) AS temp_rank
    FROM dog_temperaments_by_zip
),
dominant_temperament_per_zip AS (
    --single most common temperatment for each zip code
    --filter for rank 1, drop others 
    SELECT 
        zip_code, 
        dominant_temperament
    FROM ranked_temperaments_by_zip
    WHERE temp_rank = 1
),

total_licenses_by_zip AS (
    -- get total licensed dogs per zip code (to calculate the rate later)
    SELECT 
        dz.zipcode AS zip_code,
        COUNT(*) AS total_licensed_dogs
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
    GROUP BY dz.zipcode
),

waste_complaints_by_zip AS (
    -- count only dog waste related complaints per zip code
    SELECT 
        dl.zip_code, 
        COUNT(*) AS total_waste_complaints
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_311_dog_complaints` c
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_location` dl 
        ON c.location_key = dl.location_key
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_complaint_type` dct
        ON c.complaint_type_key = dct.complaint_type_key
    -- catch variations of dog waste in both type and descriptor columns
    WHERE LOWER(dct.complaint_type) LIKE '%waste%' 
       OR LOWER(dct.descriptor) LIKE '%waste%'
       OR LOWER(dct.descriptor) LIKE '%feces%'
    GROUP BY dl.zip_code
)

-- join everything and calculate the final metrics
SELECT 
    ds.zip_code,
    ds.dominant_size,
    dt.dominant_temperament,
    tl.total_licensed_dogs,
    -- Use COALESCE to ensure zips with 0 complaints show as 0 instead of NULL
    COALESCE(wc.total_waste_complaints, 0) AS total_waste_complaints,
    -- Calculate rate: Waste complaints per 100 licensed dogs 
    ROUND(
        (COALESCE(wc.total_waste_complaints, 0) / NULLIF(tl.total_licensed_dogs, 0)) * 100, 
        2
    ) AS waste_complaints_per_100_dogs
FROM dominant_size_per_zip ds
INNER JOIN total_licenses_by_zip tl
    ON ds.zip_code = tl.zip_code
LEFT JOIN dominant_temperament_per_zip dt
    ON ds.zip_code = dt.zip_code
-- Use LEFT JOIN here: we want to keep the zip code in our results even if it has 0 waste complaints
LEFT JOIN waste_complaints_by_zip wc
    ON ds.zip_code = wc.zip_code
WHERE ds.zip_code IS NOT NULL
ORDER BY waste_complaints_per_100_dogs DESC