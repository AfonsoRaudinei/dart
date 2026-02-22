# BASELINE V1.1 FREEZE (CONGELADO)

## Status
- **Versão**: v1.1.0
- **Data**: 2026-02-08
- **Estado**: CONGELADO (Field Ready)

## Escopo Congelado (Novas Funcionalidades)
1. **Sync de Visitas e Ocorrências**
   - Suporte Offline-First completo
   - Sincronização em background (auto-start)
   - Resolução de conflitos "Local Wins"

2. **GeoJSON e Compatibilidade**
   - Migração do modelo de dados para GeoJSON (RFC 7946)
   - Compatibilidade retroativa com lat/long legado
   - Normalização automática via `getCoordinates()`

3. **Map Occurrence Sheet**
   - Novo Bottom Sheet iOS-style para registro de ocorrências
   - Substituição do antigo AlertDialog bloqueante
   - Contrato visual Map-First (sem fotos/PDF)

## Arquivos Principais Tocados
- `lib/main.dart` (Supabase init + auto-start)
- `lib/core/services/sync_service.dart` (Orquestrador)
- `lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart` (Novo)
- `lib/modules/visitas/data/repositories/visit_sync_service.dart` (Novo)
- `lib/modules/consultoria/occurrences/domain/occurrence.dart` (GeoJSON)
- `lib/ui/components/map/map_occurrence_sheet.dart` (Novo UI)
- `lib/ui/screens/private_map_screen.dart` (Integração UI)

## Regras de Hotfix
- Apenas bugs **CRÍTICOS** (Crash, Perda de Dados, Bloqueio de Fluxo)
- UI/UX improvements estão **BLOQUEADOS** até V1.2
- Refatorações estão **PROIBIDAS**

## Checklist Mínimo de Validação (Smoke Test)
- [ ] App abre sem crash (Supabase init ok)
- [ ] Mapa carrega e centraliza
- [ ] Modo avião ativo -> Criar ocorrência -> Pin aparece
- [ ] Matar app -> Reabrir -> Pin persiste
- [ ] Online -> Log "Sync completo" (após 5min)
- [ ] Dados aparecem no SupabaseDashboard
