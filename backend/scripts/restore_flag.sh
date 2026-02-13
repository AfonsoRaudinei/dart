#!/bin/bash

# 🔄 Restore Feature Flag from Backup
# Usage: ./scripts/restore_flag.sh <environment> <backup_file>

set -e

ENVIRONMENT=$1
BACKUP_FILE=$2

if [[ -z "$ENVIRONMENT" || -z "$BACKUP_FILE" ]]; then
  echo "❌ Usage: ./scripts/restore_flag.sh <environment> <backup_file>"
  echo ""
  echo "Example:"
  echo "  ./scripts/restore_flag.sh staging data/backups/kill_switch_drawing_v1_20260212_103045.json"
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Error: Backup file not found: $BACKUP_FILE"
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
else
  echo "❌ Error: Environment must be 'staging' or 'production'"
  exit 1
fi

echo "🔄 RESTORING FLAG FROM BACKUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment: $ENVIRONMENT"
echo "Backup:      $BACKUP_FILE"
echo "API:         $API_URL"
echo ""

# Extrair flag do backup
FLAG_DATA=$(cat "$BACKUP_FILE" | jq -r '.flag')
FLAG_KEY=$(echo "$FLAG_DATA" | jq -r '.key')

echo "Flag Key: $FLAG_KEY"
echo ""

# Confirmar restauração
if [[ "$ENVIRONMENT" == "production" ]]; then
  read -p "⚠️  Restore $FLAG_KEY in PRODUCTION? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "❌ Aborted"
    exit 1
  fi
fi

# Restaurar flag
echo "🔄 Restoring flag..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$FLAG_DATA" \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "✅ Flag restored successfully!"
  echo ""
  echo "$BODY" | jq -r '.flag | "Flag:     \(.key)\nEnabled:  \(.enabled)\nRollout:  \(.rollout_percentage)%\nVersion:  \(.version)"'
else
  echo "❌ Restore failed!"
  echo "HTTP Status: $HTTP_CODE"
  echo "Response: $BODY"
  exit 1
fi

echo ""
echo "🎉 Restore complete!"
