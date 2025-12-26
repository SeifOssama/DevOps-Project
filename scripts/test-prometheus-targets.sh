#!/bin/bash
set -e

PROMETHEUS_URL="${1:-http://localhost:9090}"

echo "🧪 Testing Prometheus Targets..."

# Health check
echo "Checking Prometheus health..."
if ! curl -sf "$PROMETHEUS_URL/-/healthy" > /dev/null; then
  echo "❌ FAIL: Prometheus is not healthy"
  exit 1
fi
echo "✅ Prometheus is healthy"

# Ready check
echo "Checking Prometheus readiness..."
if ! curl -sf "$PROMETHEUS_URL/-/ready" > /dev/null; then
  echo "❌ FAIL: Prometheus is not ready"
  exit 1
fi
echo "✅ Prometheus is ready"

# Targets check
echo "Checking targets..."
TARGETS_RESPONSE=$(curl -sf "$PROMETHEUS_URL/api/v1/targets")

# Check if we have any targets
TOTAL_TARGETS=$(echo "$TARGETS_RESPONSE" | jq '.data.activeTargets | length')
if [ "$TOTAL_TARGETS" -eq 0 ]; then
  echo "❌ FAIL: No active targets found"
  exit 1
fi

echo "✅ Found $TOTAL_TARGETS active targets"

# Check expected jobs
EXPECTED_JOBS=("node-exporter" "cadvisor")

for job in "${EXPECTED_JOBS[@]}"; do
  UP_COUNT=$(echo "$TARGETS_RESPONSE" | jq "[.data.activeTargets[] | select(.labels.job == \"$job\" and .health == \"up\")] | length")
  
  if [ "$UP_COUNT" -gt 0 ]; then
    echo "✅ Job '$job' has $UP_COUNT target(s) UP"
  else
    echo "⚠️  Warning: Job '$job' has no UP targets (may still be starting)"
  fi
done

# Overall health
UP_TARGETS=$(echo "$TARGETS_RESPONSE" | jq '[.data.activeTargets[] | select(.health == "up")] | length')
DOWN_TARGETS=$(echo "$TARGETS_RESPONSE" | jq '[.data.activeTargets[] | select(.health == "down")] | length')

echo ""
echo "📊 Summary:"
echo "   UP: $UP_TARGETS"
echo "   DOWN: $DOWN_TARGETS"
echo "   TOTAL: $TOTAL_TARGETS"

if [ "$DOWN_TARGETS" -gt 0 ]; then
  echo ""
  echo "⚠️  Warning: Some targets are down"
  echo "$TARGETS_RESPONSE" | jq -r '.data.activeTargets[] | select(.health == "down") | "  ❌ \(.labels.job) - \(.labels.instance)"'
fi

echo ""
echo "🎉 Prometheus targets check completed!"
