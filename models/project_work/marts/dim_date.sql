-- Date dimension shared by both 311_Dog_Complaints and Dog_Licensing

WITH all_dates AS (
    -- Get dates from 311 requests (created date)
    SELECT DISTINCT CAST(created_date AS DATE) AS full_date
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    -- Get dates from dog licensing (issued date)
    SELECT DISTINCT CAST(license_issued_date AS DATE) AS full_date
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE license_issued_date IS NOT NULL

    UNION DISTINCT

    -- Get dates from dog licensing (expired date)
    SELECT DISTINCT CAST(license_expired_date AS DATE) AS full_date
    FROM {{ ref('stg_nyc_dog_licensing') }}
    WHERE license_expired_date IS NOT NULL
),

date_dimension AS (
    SELECT
        -- Create an Integer Date_Key (Format: YYYYMMDD) to match your ERD
        CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,

        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(MONTH FROM full_date) AS month,
        FORMAT_DATE('%B', full_date) AS month_name,
        EXTRACT(DAY FROM full_date) AS day_of_month,
        EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week,
        
        -- Boolean: True if Sunday (1) or Saturday (7)
        EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) AS is_weekend,
        
        -- Boolean: Placeholder for holidays (can be updated later if a specific holiday schedule is required)
        FALSE AS is_holiday

    FROM all_dates
)

SELECT * FROM date_dimension