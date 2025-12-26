#!/bin/bash
set -e

echo "🧪 Validating Terraform Outputs..."

# Get outputs as JSON
OUTPUTS=$(terraform output -json)

# Check monitoring node IP
MONITORING_IP=$(echo "$OUTPUTS" | jq -r '.monitoring_node_public_ip.value')
if [[ -z "$MONITORING_IP" || "$MONITORING_IP" == "null" ]]; then
  echo "❌ FAIL: Monitoring node IP is empty"
  exit 1
fi

# Validate IPv4 format
if ! echo "$MONITORING_IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
  echo "❌ FAIL: Monitoring node IP is not valid IPv4: $MONITORING_IP"
  exit 1
fi

echo "✅ Monitoring node IP: $MONITORING_IP"

# Check webserver IPs
WEBSERVER_IPS=$(echo "$OUTPUTS" | jq -r '.webserver_public_ips.value[]')
WEBSERVER_COUNT=$(echo "$WEBSERVER_IPS" | wc -l)

if [ "$WEBSERVER_COUNT" -ne 2 ]; then
  echo "❌ FAIL: Expected 2 webservers, got $WEBSERVER_COUNT"
  exit 1
fi

echo "✅ Found 2 webservers"

# Validate each webserver IP
while IFS= read -r ip; do
  if ! echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    echo "❌ FAIL: Webserver IP is not valid IPv4: $ip"
    exit 1
  fi
  echo "✅ Webserver IP: $ip"
done <<< "$WEBSERVER_IPS"

echo "🎉 All Terraform outputs validated successfully!"
