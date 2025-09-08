# Silver Layer Validation Checklist

## Source Table: `quakes_src.silver_earthquakes`

### Column Types & Casting Rules

| Column | Type | Cast Rule | Validation |
|--------|------|-----------|------------|
| `usgs_id` | string | Direct from Bronze | Not null, unique identifier |
| `event_time` | timestamp | `cast(event_time as timestamp)` | Not null, valid timestamp format |
| `event_date` | date | `cast(event_date as date)` | Not null, derived from event_time |
| `lat` | double | `cast(lat as double)` | Not null, range [-90, 90] |
| `lon` | double | `cast(lon as double)` | Not null, range [-180, 180] |
| `depth_km` | double | `cast(depth_km as double)` | Not null, positive values |
| `mag` | double | `cast(mag as double)` | Not null, typically range [0, 10] |
| `mag_type` | string | Direct from Bronze | Can be null, common values: ml, mb, mw |
| `place` | string | Direct from Bronze | Not null, location description |
| `event_type` | string | Direct from Bronze | Can be null, typically 'earthquake' |
| `mag_bucket` | string | Computed from mag | Not null, must be categorical |

### Null/Accepted-Values Rules

#### Required Not Null Columns
- `usgs_id` - Primary key from USGS
- `event_time` - Core timestamp
- `event_date` - Date partition key  
- `lat`, `lon` - Geographic coordinates
- `depth_km` - Depth measurement
- `mag` - Magnitude measurement
- `place` - Location description
- `mag_bucket` - Computed category

#### Accepted Values
- `mag_bucket`: ["M<3.0", "M3.0-3.9", "M4.0-4.9", "M5.0-5.9", "M6.0-6.9", "M>=7.0"]

#### Optional Columns
- `mag_type` - Can be null for older records
- `event_type` - Can be null, defaults to 'earthquake'

### Deduplication Key(s)

**Primary Deduplication Key**: `usgs_id`
- USGS unique identifier for each earthquake event
- Must enforce uniqueness constraint in Silver layer
- Handle updates/revisions to existing events by USGS

### _ingest_ts Convention

**Standard Pattern**: `_ingest_ts timestamp`
- Added during Bronze → Silver transformation
- Represents when record was ingested into Silver layer
- Used for incremental processing and data lineage
- Format: `current_timestamp()` at time of Silver processing

### Schema Drift Behavior

#### Expected Schema Changes
1. **New USGS Fields**
   - Add new columns with null-safe defaults
   - Update transformation logic in next deployment
   - Backfill historical data if critical

2. **Magnitude Type Evolution** 
   - New magnitude types from USGS
   - Update `mag_type` accepted values
   - Maintain backward compatibility

3. **Geographic Data Format**
   - Place name format changes
   - Coordinate precision changes  
   - Maintain existing lat/lon structure

#### Schema Drift Handling Process
1. **Detection**: Monitor for new/missing columns in source data
2. **Impact Assessment**: Evaluate downstream dependencies
3. **Graceful Degradation**: Handle missing fields with defaults
4. **Alert**: Notify data engineering team of schema changes
5. **Update**: Modify transformation logic and tests
6. **Deploy**: Test changes in staging environment first

### Data Quality Monitoring

#### Critical Checks
- Daily row count within expected ranges
- Magnitude distribution matches historical patterns
- Geographic distribution covers expected regions
- No duplicate `usgs_id` values
- All partition dates have data (detect missing days)

#### Freshness SLA
- Silver layer should be updated within 6 hours of Bronze ingestion
- Alert if no new data received for >24 hours
- USGS typically provides real-time feeds with ~5 minute delay