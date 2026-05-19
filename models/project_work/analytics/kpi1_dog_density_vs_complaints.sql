--KPI1: Licensed Dog Density vs. Complaint Density - identify correlation between the numbers of the complaints filed and the counts of licensed dogs per ZIP code.
--get the total dogs with license by zipcode
WITH dog_counts AS (
    SELECT 
        dz.zipcode AS zip_code, 
        COUNT(*) AS total_licensed_dogs
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_dog_licensing` f
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_zipcode` dz 
        ON f.zipcode_key = dz.zipcode_key
    GROUP BY dz.zipcode
),

--group the ZIP codes into density tiers based on our data distribution (quantiles)
--helps us categorize neighborhoods into 'low' to 'very high' dog populations for the map
dog_count_tiers_by_zip AS (
    SELECT 
        *,
        CASE 
            WHEN total_licensed_dogs >= 500 THEN 'very high'
            WHEN total_licensed_dogs >= 100 THEN 'high'
            WHEN total_licensed_dogs >= 25  THEN 'medium'
            ELSE 'low'
        END AS dog_density_tier,
        -- add tier_order to control sort order in Looker Studio visualizations
        -- low=1, medium=2, high=3, very high=4
        CASE 
            WHEN total_licensed_dogs >= 500 THEN 4
            WHEN total_licensed_dogs >= 100 THEN 3
            WHEN total_licensed_dogs >= 25  THEN 2
            ELSE 1
        END AS tier_order
    FROM dog_counts
),

-- total complaints per zip borough
complaint_counts_by_zip AS (
    SELECT 
        dl.zip_code AS zip_code, 
        dl.borough AS borough, 
        COUNT(*) AS total_dog_complaints
    FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_311_dog_complaints` c
    INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_location` dl 
        ON c.location_key = dl.location_key
    GROUP BY dl.zip_code, dl.borough
)

--combine the licensing data with the 311 complaints data
SELECT 
    ccz.zip_code,
    ccz.borough,
    dtz.total_licensed_dogs,
    ccz.total_dog_complaints,
    dtz.dog_density_tier,
    dtz.tier_order,
    --calculate the rate, complaints per licensed dog
    --use NULLIF to prevent the query form crashing if a ZIP has 0 licensed dogs
    ROUND(ccz.total_dog_complaints / NULLIF(dtz.total_licensed_dogs, 0), 2) AS complaints_per_licensed_dog
FROM complaint_counts_by_zip ccz
--need zip codes that appear in both dataset
INNER JOIN dog_count_tiers_by_zip dtz 
    ON ccz.zip_code = dtz.zip_code
--clean final dataset
WHERE ccz.zip_code IS NOT NULL 
  AND ccz.borough != 'Unknown' 
ORDER BY dtz.tier_order