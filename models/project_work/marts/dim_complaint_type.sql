-- Complaint Type dimension (Sourced only from 311 data)

WITH complaint_data AS (
    SELECT DISTINCT
        complaint_type,
        descriptor,
        descriptor_2 AS additional_descriptor,
        status
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE complaint_type IS NOT NULL
),

complaint_type_dimension AS (
    SELECT
        -- Generate surrogate key combining all attributes to ensure uniqueness
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type',
            'descriptor',
            'additional_descriptor',
            'status'
        ]) }} AS complaint_type_key,
        
        complaint_type,
        descriptor,
        additional_descriptor,
        status
        
    FROM complaint_data
)

SELECT * FROM complaint_type_dimension