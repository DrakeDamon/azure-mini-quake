select
  usgs_id,
  cast(event_time as timestamp) as event_time,
  cast(event_date as date)      as event_date,
  cast(lat as double)           as lat,
  cast(lon as double)           as lon,
  cast(depth_km as double)      as depth_km,
  cast(mag as double)           as mag,
  mag_type,
  place,
  event_type,
  mag_bucket
from {{ source('quakes_src','silver_earthquakes') }}