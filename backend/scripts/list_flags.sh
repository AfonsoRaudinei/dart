#!/bin/bash

# 📋 List Feature Flags
# Usage: ./scripts/list_flags.sh <environment>

set -e

ENVIRONMENT=${1:-staging}

# Determinar URL e token baseado no ambiente
if [[ "$ENVIRONMENT" == "staging" ]]; then
  API_URL="http://localhost:8080"
  ADMIN_TOKEN="staging-admin-token-2026"
elif [[ "$ENVIRONMENT" == "production" ]]; then
  API_URL="https://api.soloforte.com.br"
  ADMIN_TOKEN="${ADMIN_TOKEN:-admin-secret-token-2026}"
elif [[ "$ENVIRONMENT" == "local" ]]; then
  API_URL="http://localhost:8080"
  ADMIN_TOKEN="admin-secret-token-2026"
else
  echo "❌ Error: Environment must be 'local', 'staging', or 'production'"
  exit 1
fi

echo "📋 Feature Flags - $ENVIRONMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar flags
RESPONSE=$(curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_URL/admin/flags" 2>/dev/null)

if [[ $? -ne 0 ]]; then
  echo "❌ Error: Failed to connect to $API_URL"
  echo "Is the server running?"
  exit 1
fi

# Parse e exibir flags
echo "$RESPONSE" | jq -r '.flags[] | 
  "🎌 \(.key)\n" +
  "   Status:  " + (if .enabled then "🟢 ENABLED" else "🔴 DISABLED" end) + "\n" +
  "   Rollout: " + (.rollout_percentage | tostring) + "%\n" +
  "   Roles:   " + (.allowed_roles | join(", ")) + "\n" +
  "   Version: " + (.version | tostring) + "\n" +
  (if .min_app_version then "   Min Ver: " + .min_app_version + "\n" else "" end) +
  ""'

echo ""
TOTAL=$(echo "$RESPONSE" | jq -r '.total')
TIMESTAMP=$(echo "$RESPONSE" | jq -r '.timestamp')
echo "Total: $TOTAL flags"
echo "Updated: $TIMESTAMP"
