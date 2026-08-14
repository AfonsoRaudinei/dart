# Resumo — Ocorrências no mapa (SoloForte)

**Atualizado:** Ago/2026

## O que existe hoje

| Capacidade | Status |
|---|---|
| Pins no mapa (`occurrence_pins.dart`) | ✅ |
| Lista por viewport (`occurrence_list_sheet.dart`) | ✅ |
| Filtros (`occurrence_filters.dart`) | ✅ |
| Criação via mapa armado → `OccurrenceCreationSheet` | ✅ |
| Detalhe via pin (`occurrence_detail_sheet.dart`) | ✅ |
| Persistência offline SQLite (`local_only`) | ✅ |

## Entrada no mapa

1. **Criar:** FAB `+` → sheet de ações → **Ocorrência** → tap no mapa → formulário.
2. **Listar:** aba/tab ocorrências no `MapBottomSheet` (`isCreatingOccurrence: false`).
3. **Deep link:** `/map?modo=ocorrencia` → arma modo (sem abrir formulário antes do tap).

## O que NÃO usar (legado)

- Dialog `_openOccurrenceDialog` — removido
- `setState` local para `ArmedMode` — migrado para Riverpod
- Rota `/dashboard/ocorrencias` — substituída por estado interno em `/map`
- Placeholder "Marque o ponto no mapa" — removido; pin obrigatório antes do sheet

## Bug P0 corrigido (IPA 206 → 207)

**Sintoma:** tap no mapa abria placeholder sem formulário.  
**Causa:** `pendingOccurrenceLocationProvider` com `autoDispose` perdia coordenada antes do overlay montar.  
**Fix:** pin em `MapSheetState` + provider sem autoDispose.
