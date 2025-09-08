# Alert Matrix

## Signal → Threshold → Destination → First Diagnostic → Backfill Decision

### ADF Pipeline Failures

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| ADF Pipeline Failed | Immediate failure | Email + Teams #data-alerts | Check Databricks cluster status, review error logs | Rerun from last successful checkpoint |
| ADF Activity Failed | Single activity failure | Email to data engineering | Identify failed activity type, check dependencies | Rerun failed activity and downstream |
| Pipeline Timeout | >2 hours runtime | Teams #data-engineering | Check cluster scaling, data volume | Manual intervention, increase cluster size |

### Data Freshness Violations

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| Silver Layer Stale | No new data >24 hours | Email + Teams | Check USGS API connectivity, Bronze layer status | Backfill missing date range from USGS |
| Gold Tables Stale | No updates >36 hours | Email data owners | Verify Silver layer completeness, check dbt run logs | Full dbt rebuild if Silver is healthy |
| Real-time Feed Down | No data >6 hours | Immediate Teams alert | Contact USGS, check API endpoints | Switch to historical data feed |

### dbt Test Failures

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| `stg_earthquakes` unique test | Duplicate `usgs_id` | Email + Slack | Check for USGS data revisions, inspect duplicate records | Implement upsert logic, reprocess affected dates |
| `stg_earthquakes` not_null test | Critical columns null | Immediate Teams | Check Bronze layer data quality, USGS API issues | Identify root cause, reprocess with data fixes |
| `mag_bucket` accepted_values | Invalid magnitude buckets | Email data team | Review magnitude calculation logic, check edge cases | Update bucket logic, reprocess affected records |
| Gold layer relationship test | Orphaned records in Gold | Email analytics team | Check staging layer completeness, incremental logic | Full refresh of affected Gold tables |

### Data Volume Anomalies

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| Daily Earthquake Count | <10 or >10,000 events/day | Teams #data-quality | Check USGS feed health, global seismic activity | Verify with external sources, backfill if feed issue |
| Magnitude Distribution Shift | >50% change in avg magnitude | Email seismology team | Review data for major earthquake events, feed issues | Normal if legitimate major events, backfill if data corruption |
| Geographic Coverage Gap | Missing data from major regions | Teams alert | Check regional feed APIs, network connectivity | Backfill regional data from alternative sources |

### Infrastructure Issues

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| Databricks Cluster Down | Cluster termination | Immediate Teams | Check cluster configuration, Azure service health | Restart cluster, rerun failed jobs |
| Storage Account Issues | Access denied/throttling | Email + Teams #infrastructure | Check Azure service status, authentication | Wait for service recovery, batch retry |
| Network Connectivity | API timeouts >5min | Teams alert | Check VPN/firewall, USGS service status | Retry with backoff, use cached data if critical |

### Business Critical Alerts

| Signal | Threshold | Destination | First Diagnostic | Backfill Decision |
|--------|-----------|-------------|------------------|-------------------|
| Major Earthquake (M≥7.0) | Magnitude ≥7.0 detected | Immediate Teams + Email executives | Verify earthquake details, notify stakeholders | Prioritize data processing, ensure rapid updates |
| Missing High-Profile Events | Known major earthquakes not in data | Teams #data-quality | Check USGS delays, API filtering | Emergency backfill for missed critical events |
| Dashboard Outage | Gold tables unavailable | Email dashboard users | Check table permissions, cluster status | Restore service, backfill any missing recent data |

## Alert Configuration

### Teams Channels
- `#data-alerts` - General data issues  
- `#data-engineering` - Technical pipeline issues
- `#data-quality` - Data validation failures
- `#infrastructure` - Platform/service issues

### Email Lists
- `data-engineering@company.com` - Technical team
- `analytics-team@company.com` - Business users  
- `executives@company.com` - Critical business events

### Escalation Matrix
1. **Immediate** (0-15 minutes): Teams notification
2. **Urgent** (15-60 minutes): Email + Teams, on-call notification
3. **Critical** (60+ minutes): Manager escalation, incident declared

### Alert Suppression
- Suppress duplicate alerts for same issue within 2 hours
- Business hours vs. off-hours different thresholds
- Maintenance window alert suppression