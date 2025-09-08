# Feature Table Specification

## Feature Mart: `earthquake_features`

### Overview
A comprehensive feature mart for earthquake analytics providing daily aggregations and derived features for machine learning and advanced analytics use cases.

### Table Grain
- **Primary Grain**: `event_date` (daily aggregations)
- **Time Key**: `event_date` 
- **Update Pattern**: Daily incremental refresh
- **Retention**: 5 years of historical features

### Feature Categories

#### 1. Volume Features
**7-Day Rolling Earthquake Count** (`quakes_7d_rolling`)
- **Description**: Rolling count of earthquakes in the past 7 days
- **Calculation**: `SUM(daily_quake_count) OVER (ORDER BY event_date ROWS 6 PRECEDING)`  
- **Use Case**: Identify periods of increased seismic activity
- **Data Type**: INTEGER

#### 2. Magnitude Features  
**Normalized Average Magnitude** (`mag_avg_normalized`)
- **Description**: Z-score normalized daily average magnitude
- **Calculation**: `(daily_avg_mag - global_avg_mag) / global_stddev_mag`
- **Use Case**: Anomaly detection for unusual magnitude patterns
- **Data Type**: DOUBLE
- **Range**: Typically [-3.0, 3.0]

#### 3. Binary Indicators
**Major Earthquake Indicator** (`major_quake_indicator`) 
- **Description**: Binary flag indicating if any earthquake ≥6.0 magnitude occurred that day
- **Calculation**: `CASE WHEN max_daily_mag >= 6.0 THEN 1 ELSE 0 END`
- **Use Case**: Alert systems and risk assessment
- **Data Type**: INTEGER  
- **Values**: [0, 1]

#### 4. Categorical Features
**Depth Category** (`depth_category`)
- **Description**: Categorical encoding of average earthquake depth
- **Categories**:
  - "shallow": 0-70 km depth
  - "intermediate": 70-300 km depth  
  - "deep": >300 km depth
- **Calculation**: Based on daily average depth
- **Use Case**: Geological analysis and risk modeling
- **Data Type**: STRING

#### 5. Geographic Features
**Geographic Cluster** (`geographic_cluster`)
- **Description**: K-means cluster assignment based on daily centroid of earthquake activity
- **Clusters**: 8 geographic regions (0-7)
- **Calculation**: K-means on daily weighted lat/lon centroid
- **Use Case**: Regional pattern analysis
- **Data Type**: INTEGER
- **Values**: [0, 1, 2, 3, 4, 5, 6, 7]

### Sample Feature Table Structure

```sql
CREATE TABLE earthquake_features (
  event_date DATE NOT NULL,
  quakes_7d_rolling INTEGER NOT NULL,
  mag_avg_normalized DOUBLE NOT NULL,
  major_quake_indicator INTEGER NOT NULL,
  depth_category STRING NOT NULL,
  geographic_cluster INTEGER NOT NULL,
  -- Metadata columns
  feature_generated_at TIMESTAMP NOT NULL,
  data_source_version STRING NOT NULL
) 
USING DELTA
PARTITIONED BY (event_date)
```

### Feature Engineering Logic

#### Base Aggregations (Daily)
```sql
WITH daily_stats AS (
  SELECT 
    event_date,
    COUNT(*) as daily_quake_count,
    AVG(mag) as daily_avg_mag,
    MAX(mag) as max_daily_mag,
    AVG(depth_km) as daily_avg_depth,
    AVG(lat) as daily_centroid_lat,
    AVG(lon) as daily_centroid_lon
  FROM {{ ref('stg_earthquakes') }}
  GROUP BY event_date
)
```

#### Rolling Window Features
```sql
, rolling_features AS (
  SELECT *,
    SUM(daily_quake_count) OVER (
      ORDER BY event_date 
      ROWS 6 PRECEDING
    ) as quakes_7d_rolling
  FROM daily_stats  
)
```

#### Normalization (Global Statistics)
- **Global Average Magnitude**: 2.1 (computed from historical data)
- **Global StdDev Magnitude**: 0.8 (computed from historical data)
- **Recalculation**: Monthly update of global statistics

### Data Quality Tests

#### Uniqueness & Completeness
- `event_date` - unique, not null
- All feature columns - not null
- Complete date range (no gaps in daily data)

#### Value Validation  
- `quakes_7d_rolling` - positive integer, reasonable range [0, 10000]
- `mag_avg_normalized` - finite number, typically [-5, 5]
- `major_quake_indicator` - accepted values [0, 1]
- `depth_category` - accepted values ["shallow", "intermediate", "deep"] 
- `geographic_cluster` - accepted values [0, 1, 2, 3, 4, 5, 6, 7]

#### Business Logic Tests
- Rolling counts should be monotonically increasing or stable
- Major earthquake indicator consistent with max daily magnitude
- Geographic clusters should have reasonable geographic coherence

### Relationships & Referential Integrity
- `event_date` must exist in `stg_earthquakes` (at least one earthquake that day)
- Feature values should be derivable from corresponding `stg_earthquakes` records
- No orphaned feature records without source data

### Freshness Requirements
- Features must be updated within 24 hours of source data availability
- Alert if feature generation fails or is >48 hours stale
- Backfill capability for historical feature regeneration

### Performance Considerations

#### Partitioning Strategy
- Partition by `event_date` for efficient time-range queries
- Target 100MB-200MB files per partition
- Optimize for analytical workloads (wide table scans)

#### Indexing & Optimization
- Z-ORDER by `(event_date, geographic_cluster)` for common query patterns
- Pre-aggregate common feature combinations
- Consider materialized views for frequently-used feature subsets

### Usage Examples

#### Model Training Dataset
```sql
SELECT 
  event_date,
  quakes_7d_rolling,
  mag_avg_normalized, 
  major_quake_indicator,
  depth_category,
  geographic_cluster
FROM earthquake_features
WHERE event_date >= '2023-01-01'
  AND event_date <= '2023-12-31'
ORDER BY event_date
```

#### Real-time Anomaly Detection
```sql  
SELECT event_date, quakes_7d_rolling
FROM earthquake_features  
WHERE event_date = CURRENT_DATE - 1
  AND quakes_7d_rolling > (
    SELECT PERCENTILE(quakes_7d_rolling, 0.95) 
    FROM earthquake_features 
    WHERE event_date >= CURRENT_DATE - 365
  )
```

### Maintenance & Evolution

#### Feature Updates
- Add new features as additional columns (backward compatible)
- Version control feature definitions  
- A/B testing framework for feature variants

#### Historical Backfill
- Full backfill capability for new features
- Incremental backfill for feature logic updates
- Point-in-time feature values for model reproducibility