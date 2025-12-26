#!/bin/bash
set -e

echo "🧪 Validating Ansible Inventory..."

# List inventory
INVENTORY_JSON=$(ansible-inventory -i inventory/aws_ec2.yml --list)

# Check for monitoring node(s)
MONITORING_COUNT=$(echo "$INVENTORY_JSON" | jq '[._meta.hostvars | to_entries[] | select(.key | contains("monitoring"))] | length')

if [ "$MONITORING_COUNT" -lt 1 ]; then
  echo "❌ FAIL: Expected at least 1 monitoring node, got $MONITORING_COUNT"
  exit 1
fi
echo "✅ Found $MONITORING_COUNT monitoring node(s)"

# Check for webservers
WEBSERVER_COUNT=$(echo "$INVENTORY_JSON" | jq '[._meta.hostvars | to_entries[] | select(.key | contains("webserver"))] | length')

if [ "$WEBSERVER_COUNT" -ne 2 ]; then
  echo "❌ FAIL: Expected 2 webservers, got $WEBSERVER_COUNT"
  exit 1
fi
echo "✅ Found 2 webservers"

# Check for tag-based groups (AWS EC2 dynamic inventory groups by tags)
echo ""
echo "📋 Available groups:"
echo "$INVENTORY_JSON" | jq -r 'keys[] | select(. != "_meta" and . != "all")' | sort

echo ""
echo "🎉 Inventory structure validated successfully!"
