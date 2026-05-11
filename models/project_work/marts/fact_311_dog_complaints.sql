-- Fact table for 311 Dog Complaints
WITH stg_311 AS (
    SELECT * FROM {{ ref('stg_311nyc_service_requests') }}
),

dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),

dim_complaint AS (
    SELECT * FROM {{ ref('dim_complaint_type') }}
),

dim_address AS (
    SELECT * FROM {{ ref('dim_incident_address') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
),

dim_location_type AS (
    SELECT * FROM {{ ref('dim_location_type') }}
),

fact_311_complaints AS (
    SELECT
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['s.request_id']) }} AS complaint_event_key,

        -- Natural key
        CAST(s.request_id AS STRING) AS request_id,

        -- Event timestamps
        CAST(s.created_date AS TIMESTAMP) AS complaint_created_timestamp,
        CAST(s.closed_date AS TIMESTAMP) AS complaint_closed_timestamp,

        -- Dimension keys
        d_created.date_key AS created_date_key,
        d_closed.date_key AS closed_date_key,
        d_comp.complaint_type_key,
        d_addr.incident_address_key AS incident_address_key,
        d_loc.location_key AS location_key,
        d_loc_type.location_type_key AS location_type_key,

        -- Measures
        CASE
            WHEN s.closed_date IS NOT NULL
            THEN DATE_DIFF(CAST(s.closed_date AS DATE), CAST(s.created_date AS DATE), DAY)
            ELSE NULL
        END AS days_to_resolve,

        -- Flags
        CASE WHEN UPPER(s.status) = 'CLOSED' THEN TRUE ELSE FALSE END AS is_closed,

        -- Degenerate dimensions
        CAST(s.status AS STRING) AS status,
        CAST(s.borough AS STRING) AS borough,
        CAST(s.incident_zip AS STRING) AS incident_zip

    FROM stg_311 s
    
    LEFT JOIN dim_date d_created
        ON CAST(s.created_date AS DATE) = d_created.full_date
    LEFT JOIN dim_date d_closed
        ON CAST(s.closed_date AS DATE) = d_closed.full_date
    LEFT JOIN dim_complaint d_comp
        ON s.complaint_type = d_comp.complaint_type 
        AND COALESCE(s.descriptor, 'Unknown') = d_comp.descriptor
    LEFT JOIN dim_address d_addr
        ON s.community_board = d_addr.community_board 
        AND s.council_district = d_addr.council_district
        
    --  location  JOIN
    LEFT JOIN dim_location d_loc
        ON s.borough = d_loc.borough
        AND s.incident_zip = d_loc.zip_code
        
    -- location_type  JOIN
    LEFT JOIN dim_location_type d_loc_type
        ON s.location_type = d_loc_type.location_type
)

SELECT * FROM fact_311_complaints