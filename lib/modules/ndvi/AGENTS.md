# AGENTS.md — ndvi

## Bounded context

`ndvi/` consome, processa e apresenta analises de vegetacao por talhao.

## Contratos e dependencias

- Consumir **`IFieldLookup`** via `core/contracts/i_field_lookup_provider.dart` — nunca importar `drawing/` ou `consultoria/`.
- Composicao **`ChainedFieldLookup`** (drawing + consultoria) e registrada **somente** em `lib/main.dart` (ADR-042).
- Pode consumir `IFarmLookup` quando necessario.

## Invariants ADR-042 (nao alterar sem ADR novo)

1. Lookup encadeado: `FieldLookupAdapter` (primary) + `FieldLookupGeofenceAdapter` (fallback).
2. Cache TTL 24h com fingerprint `bbox|geometry` (`NdviCachePolicy`).
3. Fetch lazy multi-data via `ensureImageForDate` + stubs locais.
4. Planet fallback: `source: planet_preview`, `is_ndvi: false` — UI sem mascara verde.
5. Erros HTTP != 404 propagam para `FutureProvider` (estado `error`, nao empty silencioso).

## Proibido

- Importar `modules/consultoria/` ou `modules/drawing/` dentro de `ndvi/`.
- Substituir `ChainedFieldLookup` por adapter unico em `main.dart`.
- Gerar mascara ou imagem a partir de placeholder.
- Fazer hard delete de dados sincronizaveis.
- Bloquear mapa quando NDVI remoto falhar.
- Mascarar falha remota como "sem imagem".

## Qualidade obrigatoria

- Processamento de imagem deterministico e coberto por teste.
- Cache invalida quando origem (bbox/geometry) mudar.
- Suite obrigatoria (CI + `REGRA-NDVI` em `arch_check.sh`):
  - `test/modules/ndvi/chained_field_lookup_test.dart`
  - `test/modules/ndvi/ndvi_phase1_integration_test.dart`
  - `test/modules/ndvi/ndvi_phase2_test.dart`
  - `test/modules/ndvi/ndvi_phase3_widget_test.dart`
  - `test/supabase/ndvi_fetch_contract_test.dart`
- Rodar `flutter analyze lib/modules/ndvi/` e `./tool/arch_check.sh`.

## Referencias

- ADR-022 — modulo NDVI + `IFieldLookup`
- ADR-042 — lookup encadeado, cache, fetch lazy, Planet preview
