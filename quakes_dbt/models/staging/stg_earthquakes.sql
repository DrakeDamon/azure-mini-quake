select
  cast(event_time as timestamp) as event_time,
  cast(event_date as date)      as event_date,
  cast(mag as double)           as mag,
  mag_bucket,
  place,
  cast(lat as double)           as lat,
  cast(lon as double)           as lon,
  cast(depth_km as double)      as depth_km
from {{ source('quakes_src','silver_earthquakes') }}