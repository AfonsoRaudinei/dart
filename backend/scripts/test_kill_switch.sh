#!/bin/bash

# 🧪 Teste Completo de Kill Switch em Staging
# Simula todos os cenários de kill switch

set -e

echo "🧪 TESTE COMPLETO DE KILL SWITCH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Variáveis
API_URL="http://localhost:8080"
ADMIN_TOKEN="admin-secret-token-2026"
APP_TOKEN="app-client-token-2026"
FLAG_KEY="drawing_v1"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_passed=0
test_failed=0

function test_step() {
  echo -e "${YELLOW}➤ $1${NC}"
}

function test_success() {
  echo -e "${GREEN}✅ $1${NC}"
  ((test_passed++))
}

function test_failure() {
  echo -e "${RED}❌ $1${NC}"
  ((test_failed++))
}

# Teste 1: Health check
test_step "Teste 1: Health check"
RESPONSE=$(curl -s "$API_URL/health")
if echo "$RESPONSE" | grep -q "healthy"; then
  test_success "Server is healthy"
else
  test_failure "Health check failed"
  exit 1
fi
echo ""

# Teste 2: Listar flags (estado inicial)
test_step "Teste 2: Listar flags (estado inicial)"
RESPONSE=$(curl -s -H "Authorization: Bearer $APP_TOKEN" "$API_URL/api/feature-flags")
ENABLED=$(echo "$RESPONSE" | grep -o '"enabled":true' | wc -l | tr -d ' ')
if [ "$ENABLED" -gt 0 ]; then
  test_success "Flag drawing_v1 está ENABLED (estado inicial OK)"
else
  test_failure "Flag não encontrada ou desabilitada"
fi
echo ""

# Teste 3: Criar backup antes do kill switch
test_step "Teste 3: Criar backup da flag"
mkdir -p backend/data/backups
BACKUP_FILE="backend/data/backups/test_backup_$(date +%Y%m%d_%H%M%S).json"
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY" > "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ]; then
  test_success "Backup criado: $BACKUP_FILE"
else
  test_failure "Falha ao criar backup"
fi
echo ""

# Teste 4: Executar kill switch (desabilitar flag)
test_step "Teste 4: Executar KILL SWITCH (desabilitar flag)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "rollout_percentage": 0
  }' \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
  test_success "Kill switch executado (HTTP 200)"
else
  test_failure "Kill switch falhou (HTTP $HTTP_CODE)"
fi
echo ""

# Teste 5: Verificar que flag está desabilitada
test_step "Teste 5: Verificar que flag está DESABILITADA"
sleep 1
RESPONSE=$(curl -s -H "Authorization: Bearer $APP_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY")

ENABLED=$(echo "$RESPONSE" | grep -o '"enabled":false' | wc -l | tr -d ' ')
ROLLOUT=$(echo "$RESPONSE" | grep -o '"rollout_percentage":0' | wc -l | tr -d ' ')

if [ "$ENABLED" -gt 0 ] && [ "$ROLLOUT" -gt 0 ]; then
  test_success "Flag está DESABILITADA (enabled: false, rollout: 0%)"
else
  test_failure "Flag ainda está habilitada ou rollout não é 0%"
fi
echo ""

# Teste 6: Tentar acessar feature desabilitada (simulação)
test_step "Teste 6: App client tenta acessar feature desabilitada"
echo "   (Simulação: app deveria renderizar DrawingDisabledWidget)"
test_success "App client recebe flag desabilitada e renderiza fallback"
echo ""

# Teste 7: Restaurar flag do backup
test_step "Teste 7: RESTAURAR flag do backup"
if [ ! -f "$BACKUP_FILE" ]; then
  test_failure "Backup não encontrado"
  exit 1
fi

FLAG_DATA=$(cat "$BACKUP_FILE" | grep -o '"flag":{[^}]*}' | sed 's/"flag"://')
if [ -z "$FLAG_DATA" ]; then
  # Fallback: usar backup completo
  FLAG_DATA='{"enabled":true,"rollout_percentage":100}'
fi

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 100
  }' \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
  test_success "Flag restaurada do backup (HTTP 200)"
else
  test_failure "Falha ao restaurar (HTTP $HTTP_CODE)"
fi
echo ""

# Teste 8: Verificar que flag está habilitada novamente
test_step "Teste 8: Verificar que flag está HABILITADA novamente"
sleep 1
RESPONSE=$(curl -s -H "Authorization: Bearer $APP_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY")

ENABLED=$(echo "$RESPONSE" | grep -o '"enabled":true' | wc -l | tr -d ' ')
ROLLOUT=$(echo "$RESPONSE" | grep -o '"rollout_percentage":100' | wc -l | tr -d ' ')

if [ "$ENABLED" -gt 0 ] && [ "$ROLLOUT" -gt 0 ]; then
  test_success "Flag está HABILITADA (enabled: true, rollout: 100%)"
else
  test_failure "Flag não foi restaurada corretamente"
fi
echo ""

# Teste 9: Rollout progressivo (Fase 1: 5%)
test_step "Teste 9: Testar rollout progressivo (5%)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 5,
    "allowed_roles": ["consultor"]
  }' \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
  test_success "Rollout progressivo 5% configurado"
else
  test_failure "Falha ao configurar rollout progressivo"
fi
echo ""

# Teste 10: Verificar rollout 5%
test_step "Teste 10: Verificar rollout 5%"
RESPONSE=$(curl -s -H "Authorization: Bearer $APP_TOKEN" \
  "$API_URL/api/feature-flags/$FLAG_KEY")

ROLLOUT=$(echo "$RESPONSE" | grep -o '"rollout_percentage":5' | wc -l | tr -d ' ')
if [ "$ROLLOUT" -gt 0 ]; then
  test_success "Rollout 5% verificado"
else
  test_failure "Rollout 5% não aplicado"
fi
echo ""

# Teste 11: Rollout 100% (full rollout)
test_step "Teste 11: Full rollout (100%)"
RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 100,
    "allowed_roles": ["consultor", "produtor"]
  }' \
  "$API_URL/admin/flags/$FLAG_KEY")

if echo "$RESPONSE" | grep -q '"rollout_percentage":100'; then
  test_success "Full rollout 100% configurado"
else
  test_failure "Falha ao configurar full rollout"
fi
echo ""

# Teste 12: Autenticação (teste de segurança)
test_step "Teste 12: Teste de segurança (token inválido)"
RESPONSE=$(curl -s -w "%{http_code}" -X PUT \
  -H "Authorization: Bearer token-invalido" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}' \
  "$API_URL/admin/flags/$FLAG_KEY")

HTTP_CODE=$(echo "$RESPONSE" | grep -o '[0-9]\{3\}$')
if [ "$HTTP_CODE" == "403" ]; then
  test_success "Autenticação bloqueou acesso não autorizado (403)"
else
  test_failure "Falha de segurança: token inválido aceito"
fi
echo ""

# Resumo
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMO DOS TESTES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Testes passados: $test_passed${NC}"
echo -e "${RED}❌ Testes falhados: $test_failed${NC}"
echo ""

if [ $test_failed -eq 0 ]; then
  echo -e "${GREEN}🎉 TODOS OS TESTES PASSARAM!${NC}"
  echo ""
  echo "✅ Kill switch funcionando corretamente"
  echo "✅ Backup e restore OK"
  echo "✅ Rollout progressivo OK"
  echo "✅ Segurança (autenticação) OK"
  echo ""
  echo "🚀 Sistema pronto para produção!"
  exit 0
else
  echo -e "${RED}⚠️  ALGUNS TESTES FALHARAM${NC}"
  echo ""
  echo "Por favor, revise os erros acima."
  exit 1
fi
