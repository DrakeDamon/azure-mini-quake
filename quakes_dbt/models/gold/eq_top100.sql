{{ config(materialized='table') }}

select
  event_time,
  mag,
  place,
  lat,
  lon,
  depth_km
from {{ source('quakes_src','silver_earthquakes') }}
order by mag desc
limit 100

