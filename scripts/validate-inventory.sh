#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Validating Ansible Inventory Structure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# List inventory and save to JSON
echo "📥 Fetching inventory data..."
INVENTORY_JSON=$(ansible-inventory -i inventory/aws_ec2.yml --list)

# Debug: Show raw inventory structure
echo ""
echo "🔍 Debug: Inventory Groups Found:"
echo "$INVENTORY_JSON" | jq -r 'keys[] | select(. != "_meta")' | sort

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣ Checking 'monitoring' Group"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if monitoring group exists
if ! echo "$INVENTORY_JSON" | jq -e '.monitoring' > /dev/null 2>&1; then
  echo "❌ FAIL: 'monitoring' group not found in inventory"
  echo ""
  echo "Available groups:"
  echo "$INVENTORY_JSON" | jq -r 'keys[] | select(. != "_meta" and . != "all")'
  exit 1
fi

# Count monitoring hosts
MONITORING_COUNT=$(echo "$INVENTORY_JSON" | jq '.monitoring.hosts | length')
echo "   Found: $MONITORING_COUNT host(s) in 'monitoring' group"

if [ "$MONITORING_COUNT" -lt 1 ]; then
  echo "❌ FAIL: Expected at least 1 monitoring node, got $MONITORING_COUNT"
  exit 1
fi

# Show monitoring hosts
echo "   Hosts:"
echo "$INVENTORY_JSON" | jq -r '.monitoring.hosts[]' | sed 's/^/      - /'

echo "✅ PASS: Monitoring group validated"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣ Checking 'webservers' Group"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if webservers group exists
if ! echo "$INVENTORY_JSON" | jq -e '.webservers' > /dev/null 2>&1; then
  echo "❌ FAIL: 'webservers' group not found in inventory"
  echo ""
  echo "Available groups:"
  echo "$INVENTORY_JSON" | jq -r 'keys[] | select(. != "_meta" and . != "all")'
  exit 1
fi

# Count webserver hosts
WEBSERVER_COUNT=$(echo "$INVENTORY_JSON" | jq '.webservers.hosts | length')
echo "   Found: $WEBSERVER_COUNT host(s) in 'webservers' group"

if [ "$WEBSERVER_COUNT" -ne 2 ]; then
  echo "❌ FAIL: Expected exactly 2 webservers, got $WEBSERVER_COUNT"
  exit 1
fi

# Show webserver hosts
echo "   Hosts:"
echo "$INVENTORY_JSON" | jq -r '.webservers.hosts[]' | sed 's/^/      - /'

echo "✅ PASS: Webservers group validated"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣ Checking Host Variables (ansible_host, ansible_user)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get all hosts
ALL_HOSTS=$(echo "$INVENTORY_JSON" | jq -r '._meta.hostvars | keys[]')
TOTAL_HOSTS=$(echo "$ALL_HOSTS" | wc -l)

echo "   Total hosts in inventory: $TOTAL_HOSTS"
echo ""

# Validate each host has required variables
VALIDATION_FAILED=0

for host in $ALL_HOSTS; do
  echo "   🔍 Validating: $host"
  
  # Check ansible_host (should be an IP address)
  ANSIBLE_HOST=$(echo "$INVENTORY_JSON" | jq -r "._meta.hostvars[\"$host\"].ansible_host // \"MISSING\"")
  if [ "$ANSIBLE_HOST" = "MISSING" ]; then
    echo "      ❌ Missing 'ansible_host' variable"
    VALIDATION_FAILED=1
  else
    echo "      ✅ ansible_host: $ANSIBLE_HOST"
  fi
  
  # Check ansible_user
  ANSIBLE_USER=$(echo "$INVENTORY_JSON" | jq -r "._meta.hostvars[\"$host\"].ansible_user // \"MISSING\"")
  if [ "$ANSIBLE_USER" = "MISSING" ]; then
    echo "      ❌ Missing 'ansible_user' variable"
    VALIDATION_FAILED=1
  else
    echo "      ✅ ansible_user: $ANSIBLE_USER"
  fi
  
  echo ""
done

if [ "$VALIDATION_FAILED" -eq 1 ]; then
  echo "❌ FAIL: Some hosts are missing required variables"
  exit 1
fi

echo "✅ PASS: All hosts have required variables"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣ Summary - All Available Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "$INVENTORY_JSON" | jq -r 'keys[] | select(. != "_meta" and . != "all")' | sort | sed 's/^/   - /'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Inventory Structure Validation: PASSED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
