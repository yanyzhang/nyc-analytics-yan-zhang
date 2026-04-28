-- Quick test to verify dog licensing source connection works
 SELECT
     animalname,
     animalgender,
     animalbirth,
     breedname,
     zipcode,
     licenseissueddate,
     licenseexpireddate,
     extract_year
 FROM {{ source('group5_raw', 'source_nyc_dog_licensing') }}
 LIMIT 10