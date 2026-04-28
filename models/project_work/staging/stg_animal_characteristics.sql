-- Quick test to verify animal characteristics source connection works
 SELECT
     breed_name,
     size_category,
     temperament,
     source_note
 FROM {{ source('group5_raw', 'Dim_Animal_CHaracteristics') }}
 LIMIT 10