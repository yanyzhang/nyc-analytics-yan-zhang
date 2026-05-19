-- complaints_by_month_year_zip
SELECT
    dl.borough,
    DATE(dd.year, dd.month, 1) AS complaint_date,
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(*) AS total_dog_complaints
FROM `data-analytics-project-485903.nyc_group5_raw_data_marts.fact_311_dog_complaints` c
INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_location` dl
    ON c.location_key = dl.location_key
INNER JOIN `data-analytics-project-485903.nyc_group5_raw_data_marts.dim_date` dd
    ON c.created_date_key = dd.date_key
WHERE dl.borough IN ('Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island')
GROUP BY dl.borough, dd.year, dd.month, dd.month_name
ORDER BY dd.year, dd.month