{{ config(materialized='table') }}

with s as (
  select event_date, mag_bucket, mag
  from {{ ref('stg_earthquakes') }}
)
select
  event_date,
  mag_bucket,
  count(*)           as quakes,
  round(avg(mag), 2) as avg_mag
from s
group by event_date, mag_bucket
order by event_date, mag_bucket

