#!/bin/bash
set -e

GRAFANA_URL="${1:-http://localhost:3000}"
GRAFANA_USER="${2:-admin}"
GRAFANA_PASS="${3:-admin}"

echo "🧪 Testing Grafana..."

# Health check
echo "Checking Grafana health..."
HEALTH=$(curl -sf "$GRAFANA_URL/api/health" | jq -r '.database')
if [ "$HEALTH" != "ok" ]; then
  echo "❌ FAIL: Grafana database is not healthy: $HEALTH"
  exit 1
fi
echo "✅ Grafana is healthy"

# Dashboard check
echo "Checking dashboards..."
DASHBOARD_RESPONSE=$(curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/search?type=dash-db" 2>/dev/null || echo "[]")
DASHBOARD_COUNT=$(echo "$DASHBOARD_RESPONSE" | jq 'length')

if [ "$DASHBOARD_COUNT" -ge 1 ]; then
  echo "✅ Found $DASHBOARD_COUNT dashboard(s)"
  echo "$DASHBOARD_RESPONSE" | jq -r '.[] | "   📊 \(.title)"'
else
  echo "ℹ️  No dashboards found (this is okay if none were provisioned)"
fi

# Datasource check
echo "Checking datasources..."
DATASOURCE_RESPONSE=$(curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/datasources" 2>/dev/null || echo "[]")
DATASOURCE_COUNT=$(echo "$DATASOURCE_RESPONSE" | jq 'length')

if [ "$DATASOURCE_COUNT" -ge 1 ]; then
  echo "✅ Found $DATASOURCE_COUNT datasource(s)"
  echo "$DATASOURCE_RESPONSE" | jq -r '.[] | "   🔌 \(.name) (\(.type))"'
else
  echo "ℹ️  No datasources found"
fi

echo ""
echo "🎉 Grafana validated successfully!"
