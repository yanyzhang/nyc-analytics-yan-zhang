-- Fact Table for 311 Dog Complaints

WITH complaints_data AS (
    SELECT * FROM {{ ref('stg_311nyc_service_requests') }}
),

final_fact AS (
    SELECT
        -- Primary Key
        request_id AS unique_key,

        -- ---------------------------------------------------------
        -- FOREIGN KEYS linking to your dimensions
        -- ---------------------------------------------------------
        {{ dbt_utils.generate_surrogate_key([
            'incident_address',
            'street_name',
            'address_type',
            'city',
            'community_board',
            'council_district'
        ]) }} AS incident_address_key,

        {{ dbt_utils.generate_surrogate_key([
            'complaint_type',
            'descriptor',
            'descriptor_2', 
            'status'
        ]) }} AS complaint_type_key,

        {{ dbt_utils.generate_surrogate_key(['borough', 'incident_zip']) }} AS zipcode_key,

        {{ dbt_utils.generate_surrogate_key(['agency_name']) }} AS agency_key,

        {{ dbt_utils.generate_surrogate_key(['location_type']) }} AS location_type_key,

        {{ dbt_utils.generate_surrogate_key(['latitude', 'longitude']) }} AS location_id,

        -- Integer Date Key (YYYYMMDD)
        CAST(FORMAT_DATE('%Y%m%d', created_date) AS INT64) AS created_date_key,

        -- ---------------------------------------------------------
        -- ATTRIBUTES
        -- ---------------------------------------------------------
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude

    FROM complaints_data
)

SELECT * FROM final_fact