#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
# Script de Auditoria: MapController Lifecycle Guard
# ════════════════════════════════════════════════════════════════════
#
# Propósito: Detectar usos do MapController sem proteção _isMapReady
# Uso: ./scripts/audit_mapcontroller.sh
# CI: Adicionar este script ao pipeline para bloquear merges inseguros
#
# ════════════════════════════════════════════════════════════════════

set -e

echo "🔍 Auditando uso do MapController..."
echo ""

TARGET_FILE="lib/ui/screens/private_map_screen.dart"

if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ Arquivo $TARGET_FILE não encontrado!"
  exit 1
fi

# ── BUSCAR TODOS OS USOS DO MAPCONTROLLER ──
echo "📍 Localizando chamadas ao MapController:"
grep -n "_mapController\." "$TARGET_FILE" || echo "  ✅ Nenhuma chamada encontrada (OK se mapa foi removido)"
echo ""

# ── VERIFICAR PRESENÇA DA FLAG DE GUARD ──
echo "🔒 Verificando presença da flag _isMapReady:"
if grep -q "bool _isMapReady" "$TARGET_FILE"; then
  echo "  ✅ Flag _isMapReady encontrada"
else
  echo "  ❌ ERRO: Flag _isMapReady NÃO encontrada!"
  echo "     O guard de proteção foi removido!"
  exit 1
fi
echo ""

# ── VERIFICAR PRESENÇA DO CALLBACK ONMAPREADY ──
echo "🎯 Verificando callback onMapReady:"
if grep -q "onMapReady:" "$TARGET_FILE"; then
  echo "  ✅ Callback onMapReady encontrado"
else
  echo "  ❌ AVISO: Callback onMapReady não encontrado!"
  echo "     Verifique se foi removido acidentalmente."
fi
echo ""

# ── AUDITORIA MANUAL: LISTAR FUNÇÕES QUE USAM MAPCONTROLLER ──
echo "📋 Funções que devem ter guard _isMapReady:"
echo "   - _handleAutoZoom"
echo "   - _centerOnUser"
echo "   - onMapReady callback"
echo "   - Condições de MarkerLayer (camera.zoom)"
echo ""

echo "🧠 CHECKLIST MANUAL:"
echo "   1. Cada uso de _mapController deve estar após verificação _isMapReady"
echo "   2. Nenhuma chamada no initState"
echo "   3. Listeners/providers devem verificar _isMapReady antes de agir"
echo ""

echo "✅ Auditoria concluída!"
echo "   Para revisão manual detalhada:"
echo "   grep -n \"_mapController\.\" $TARGET_FILE"
