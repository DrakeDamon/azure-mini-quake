# Housekeeping Schedule

## Delta Table Maintenance Configuration

### Staging Layer: `stg_earthquakes`

| Property | Configuration | Rationale |
|----------|---------------|-----------|
| **Partition Column** | `event_date` | Daily partitioning for efficient time-based queries |
| **Target File Size** | 256MB | Balance between query performance and file management |
| **OPTIMIZE Cadence** | 2× per week (Tuesday, Friday) | Handle daily ingestion without over-optimizing |
| **VACUUM Retention** | 7 days | Short retention for staging layer, reduce storage costs |
| **Z-ORDER Columns** | `usgs_id, event_date` | Optimize for unique lookups and time range queries |
| **Owner** | Data Engineering Team | Responsible for ETL pipeline maintenance |
| **Business Hours** | Run during off-peak: 2 AM - 4 AM PST | Minimize impact on downstream processes |

```sql
-- Example OPTIMIZE command
OPTIMIZE hive_metastore.quakes.stg_earthquakes 
ZORDER BY (usgs_id, event_date);

-- Example VACUUM command  
VACUUM hive_metastore.quakes.stg_earthquakes RETAIN 168 HOURS;
```

### Gold Layer: `eq_daily_metrics`

| Property | Configuration | Rationale |
|----------|---------------|-----------|
| **Partition Column** | `event_date` | Align with business reporting by date |
| **Target File Size** | 128MB | Smaller files for analytical workloads |
| **OPTIMIZE Cadence** | Weekly (Sunday 3 AM) | Lower update frequency, stable aggregations |
| **VACUUM Retention** | 30 days | Longer retention for business continuity |
| **Z-ORDER Columns** | `event_date, mag_bucket` | Optimize for time series and magnitude analysis |
| **Owner** | Analytics Team | Business logic ownership |
| **Dependencies** | `stg_earthquakes` OPTIMIZE must complete first | Ensure source stability |

```sql
-- Example OPTIMIZE command
OPTIMIZE hive_metastore.quakes.eq_daily_metrics 
ZORDER BY (event_date, mag_bucket);

-- Example VACUUM command
VACUUM hive_metastore.quakes.eq_daily_metrics RETAIN 720 HOURS;
```

### Gold Layer: `eq_top100`

| Property | Configuration | Rationale |
|----------|---------------|-----------|
| **Partition Column** | None | Small table (<100 rows), partitioning overhead not justified |
| **Target File Size** | Single file | Minimal data volume |
| **OPTIMIZE Cadence** | Monthly (1st Sunday) | Infrequent updates to top earthquakes |
| **VACUUM Retention** | 30 days | Standard retention for Gold layer |
| **Z-ORDER Columns** | `mag DESC, event_time` | Optimize for magnitude-based sorting |
| **Owner** | Analytics Team | Business reporting table |
| **Special Notes** | Full refresh pattern, no incremental updates | Complete rebuild on each run |

```sql
-- Example OPTIMIZE command  
OPTIMIZE hive_metastore.quakes.eq_top100 
ZORDER BY (mag, event_time);

-- Example VACUUM command
VACUUM hive_metastore.quakes.eq_top100 RETAIN 720 HOURS;
```

## Automated Maintenance Schedule

### Weekly Schedule (All times PST)

| Day | Time | Task | Tables | Owner |
|-----|------|------|--------|-------|
| **Tuesday** | 2:00 AM | OPTIMIZE | `stg_earthquakes` | Data Engineering |
| **Friday** | 2:00 AM | OPTIMIZE | `stg_earthquakes` | Data Engineering |
| **Sunday** | 3:00 AM | OPTIMIZE + VACUUM | `eq_daily_metrics` | Analytics Team |
| **Sunday** | 3:30 AM | OPTIMIZE + VACUUM | `eq_top100` | Analytics Team |

### Monthly Schedule

| Week | Task | Tables | Notes |
|------|------|--------|-------|
| **1st Sunday** | Full maintenance cycle | All tables | Complete OPTIMIZE + VACUUM + statistics update |
| **3rd Sunday** | Health check | All tables | Verify file sizes, partition counts, performance metrics |

### Monitoring & Alerting

#### Table Health Metrics
- File count per partition (alert if >1000 files)
- Average file size (alert if <64MB for staging, <32MB for Gold)
- Partition count growth rate
- Query performance degradation (>20% slower)

#### Maintenance Job Monitoring
- OPTIMIZE job duration (alert if >2x normal duration)
- VACUUM space reclamation (alert if <10% space freed)
- Failed maintenance jobs (immediate alert)

### Emergency Procedures

#### High File Count (>1000 files per partition)
1. **Immediate**: Run emergency OPTIMIZE on affected partition
2. **Investigation**: Check for streaming ingestion issues
3. **Prevention**: Adjust file size targets or ingestion batch size

#### Storage Cost Spike
1. **Immediate**: Run VACUUM with shorter retention (24 hours emergency retention)
2. **Investigation**: Identify tables with excessive small files
3. **Action**: Aggressive OPTIMIZE schedule for 1 week

#### Performance Degradation
1. **Immediate**: Check for missing statistics, outdated Z-ORDER
2. **Action**: Run `ANALYZE TABLE ... COMPUTE STATISTICS`
3. **Follow-up**: Review Z-ORDER column effectiveness

### Cost Optimization

#### Storage Efficiency Targets
- **Staging**: <$50/month storage cost
- **Gold Layer**: <$25/month storage cost  
- **Overall**: 90% storage efficiency (actual data vs. metadata overhead)

#### Compute Optimization
- Batch maintenance jobs during reserved capacity hours
- Use smaller clusters for VACUUM operations
- Schedule OPTIMIZE during low-traffic periods

### Ownership & Responsibilities

#### Data Engineering Team
- Staging layer maintenance
- Infrastructure health monitoring
- Emergency response procedures
- Maintenance job automation

#### Analytics Team  
- Gold layer maintenance
- Business logic validation after maintenance
- Performance impact assessment
- Cost monitoring and optimization