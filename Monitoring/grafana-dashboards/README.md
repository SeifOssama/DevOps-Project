# Grafana Dashboards

## Overview
This directory contains Grafana dashboard JSON files that will be automatically provisioned when the monitoring stack deploys.

## How to Add Dashboards

### Option 1: Download from Grafana.com

1. Visit [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
2. Find your desired dashboard, for example:
   - **Node Exporter Full** (ID: 1860) - Comprehensive system metrics
   - **Docker Container & Host Metrics** (ID: 893) - Docker monitoring
   - **cAdvisor Exporter** (ID: 14282) - Container metrics

3. Download the JSON file:
   - Click on the dashboard
   - Click "Download JSON"
   - Save to this directory (`Monitoring/grafana-dashboards/`)

4. Name the file descriptively:
   - `node-exporter-full.json`
   - `docker-monitoring.json`
   - `cadvisor-metrics.json`

### Option 2: Export from Grafana UI

1. Access Grafana: `http://<monitoring-ip>:3000`
2. Login with `admin/admin`
3. Create or customize your dashboard
4. Click "Share dashboard" → "Export" → "Save to file"
5. Save the JSON file to this directory

## Automatic Provisioning

All JSON files in this directory will be automatically:
- Copied to the monitoring node during Ansible playbook execution
- Loaded into Grafana via the provisioning system
- Available immediately after deployment

## Recommended Dashboards

For this project, we recommend:
- **Node Exporter Full (1860)** - Host system metrics
- **Docker Container Monitoring** - Container resource usage
- **Prometheus 2.0 Stats** - Prometheus internal metrics

## Current Dashboards

*Place your downloaded dashboard JSON files here*

- [ ] `node-exporter-full.json` (TODO: Download from Grafana ID 1860)
- [ ] `docker-monitoring.json` (TODO: Download from Grafana ID 893)
- [ ] (Add more as needed)
