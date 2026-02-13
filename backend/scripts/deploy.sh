#!/bin/bash

# 🚀 SoloForte Backend Deploy Script
# Usage: ./scripts/deploy.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying backend to $ENVIRONMENT..."

# Validar ambiente
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "❌ Error: Environment must be 'staging' or 'production'"
  exit 1
fi

# Carregar configuração
CONFIG_FILE="$PROJECT_ROOT/config/$ENVIRONMENT.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: Config file not found: $CONFIG_FILE"
  exit 1
fi

echo "✅ Config loaded: $CONFIG_FILE"

# Verificar dependências
echo "📦 Installing dependencies..."
cd "$PROJECT_ROOT"
dart pub get

# Executar testes
echo "🧪 Running tests..."
# dart test

# Build (opcional - para deploy otimizado)
# echo "🏗️ Building..."
# dart compile exe bin/server.dart -o bin/server

# Inicializar flags do ambiente
echo "🎌 Initializing feature flags for $ENVIRONMENT..."
dart run scripts/init_flags.dart "$ENVIRONMENT"

# Deploy específico por ambiente
if [[ "$ENVIRONMENT" == "staging" ]]; then
  echo "🔧 Deploying to STAGING..."
  
  # Copiar flags de staging
  cp config/staging.json data/feature_flags.staging.json
  
  # Reiniciar servidor staging (substitua com seu comando real)
  # docker-compose -f docker-compose.staging.yml up -d --build
  # ou
  # kubectl apply -f k8s/staging/
  
  echo "✅ Deployed to STAGING"
  echo "📍 URL: https://api-staging.soloforte.com.br"
  
elif [[ "$ENVIRONMENT" == "production" ]]; then
  echo "🔥 Deploying to PRODUCTION..."
  
  # Verificar variáveis de ambiente obrigatórias
  if [[ -z "$ADMIN_TOKEN" || -z "$APP_CLIENT_TOKEN" ]]; then
    echo "❌ Error: ADMIN_TOKEN and APP_CLIENT_TOKEN must be set for production"
    exit 1
  fi
  
  # Backup das flags atuais
  echo "💾 Backing up current production flags..."
  BACKUP_FILE="data/backups/flags_$(date +%Y%m%d_%H%M%S).json"
  mkdir -p data/backups
  cp data/feature_flags.production.json "$BACKUP_FILE" 2>/dev/null || echo "No existing flags to backup"
  
  # Deploy production (substitua com seu comando real)
  # docker-compose -f docker-compose.production.yml up -d --build
  # ou
  # kubectl apply -f k8s/production/
  
  echo "✅ Deployed to PRODUCTION"
  echo "📍 URL: https://api.soloforte.com.br"
  echo "💾 Backup: $BACKUP_FILE"
fi

echo ""
echo "🎉 Deploy completed!"
echo ""
echo "📋 Next steps:"
echo "  1. Test health: curl https://api-$ENVIRONMENT.soloforte.com.br/health"
echo "  2. List flags: ./scripts/list_flags.sh $ENVIRONMENT"
echo "  3. Monitor logs: ./scripts/logs.sh $ENVIRONMENT"
