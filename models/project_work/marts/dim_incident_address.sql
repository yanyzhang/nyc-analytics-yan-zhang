WITH address_data AS (
    SELECT DISTINCT
        community_board,
        council_district
    FROM {{ ref('stg_311nyc_service_requests') }}
    WHERE community_board IS NOT NULL
        AND council_district IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'community_board',
        'council_district'
    ]) }} AS incident_address_key,
    community_board,
    council_district
FROM address_data