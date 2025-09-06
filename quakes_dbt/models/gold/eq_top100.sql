{{ config(materialized='table') }}

select
  event_time,
  mag,
  place,
  lat,
  lon,
  depth_km
from {{ ref('stg_earthquakes') }}
order by mag desc
limit 100

