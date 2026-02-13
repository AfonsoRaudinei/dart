#!/bin/bash

# 🚨 Feature Flag Kill Switch
# Desabilita IMEDIATAMENTE uma feature flag em qualquer ambiente
# Usage: ./scripts/kill_switch.sh <environment> <flag_key>

set -e

ENVIRONMENT=$1
FLAG_KEY=$2

if [[ -z "$ENVIRONMENT" || -z "$FLAG_KEY" ]]; then
  echo "❌ Usage: ./scripts/kill_switch.sh <environment> <flag_key>"
  echo ""
  echo "Examples:"
  echo "  ./scripts/kill_switch.sh staging drawing_v1"
  echo "  ./scripts/kill_switch.sh production drawing_v1"
  exit 1
fi

# Validar ambiente
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "❌ Error: Environment must be 'staging' or 'production'"
  exit 1
fi

# Determinar URL e token baseado no ambiente
if [[ "$ENVIRONMENT" == "staging" ]]; then
  API_URL="http://localhost:8080"
  ADMIN_TOKEN="staging-admin-token-2026"
elif [[ "$ENVIRONMENT" == "production" ]]; then
  API_URL="https://api.soloforte.com.br"
  ADMIN_TOKEN="${ADMIN_TOKEN}"
  
  if [[ -z "$ADMIN_TOKEN" ]]; then
    echo "❌ Error: ADMIN_TOKEN environment variable not set for production"
    exit 1
  fi
fi

echo "🚨 KILL SWITCH ACTIVATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment: $ENVIRONMENT"
echo "Flag:        $FLAG_KEY"
echo "API:         $API_URL"
echo ""

# Confirmar ação
if [[ "$ENVIRONMENT" == "production" ]]; then
  read -p "⚠️  This will disable $FLAG_KEY in PRODUCTION. Continue? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "❌ Aborted"
    exit 1
  fi
fi

# Backup da flag atual
echo "💾 Backing up current flag state..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="data/backups/kill_switch_${FLAG_KEY}_${TIMESTAMP}.json"
mkdir -p data/backups

curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY" > "$BACKUP_FILE" || true

echo "✅ Backup saved: $BACKUP_FILE"

# Executar kill switch
echo ""
echo "🔴 Disabling flag $FLAG_KEY..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "rollout_percentage": 0
  }' \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "✅ Kill switch executed successfully!"
  echo ""
  echo "$BODY" | jq -r '.flag | "Flag:     \(.key)\nEnabled:  \(.enabled)\nRollout:  \(.rollout_percentage)%\nVersion:  \(.version)"'
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Flag $FLAG_KEY is now DISABLED in $ENVIRONMENT"
  echo "💾 Backup: $BACKUP_FILE"
  echo ""
  echo "📋 To restore, run:"
  echo "   ./scripts/restore_flag.sh $ENVIRONMENT $BACKUP_FILE"
else
  echo "❌ Kill switch failed!"
  echo "HTTP Status: $HTTP_CODE"
  echo "Response: $BODY"
  exit 1
fi

# Verificar propagação
echo ""
echo "🔍 Verifying flag is disabled..."
sleep 2

VERIFY=$(curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY" | jq -r '.flag.enabled')

if [[ "$VERIFY" == "false" ]]; then
  echo "✅ Verified: Flag is disabled and propagated"
else
  echo "⚠️  Warning: Flag might not be fully propagated yet"
fi

echo ""
echo "🎉 Kill switch complete!"
