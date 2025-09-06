select
  cast(event_time as timestamp) as event_time,
  cast(mag as double)           as mag,
  mag_bucket,
  cast(event_date as date)      as event_date
from {{ source('quakes_src','silver_earthquakes') }}