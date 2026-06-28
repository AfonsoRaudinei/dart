# ADR-042 — NDVI: lookup encadeado, cache e fetch lazy

## Status

Ativo — 2026-06-27

## Contexto

O modulo NDVI era aberto com IDs de talhao vindos de `consultoria/fields` e
`visitas/`, mas o `IFieldLookup` usado pelo repositorio lia apenas
`drawing/`. Isso gerava estado vazio mesmo com geometria valida.

Alem disso, a Edge Function retornava apenas uma imagem, o cache nunca
expirava e falhas remotas eram mascaradas como "sem imagem".

## Decisao

1. **`ChainedFieldLookup`** em `ndvi/infra/` compoe `FieldLookupAdapter`
   (drawing) + `FieldLookupGeofenceAdapter` (consultoria), registrado em
   `main.dart` via `iFieldLookupProvider`.

2. **`NdviCachePolicy`** com TTL de 24h e fingerprint de
   `bbox|geometry` via `PreferencesService`.

3. **`NdviRemoteFetchResult`** transporta `image` + `available_dates`; o
   repositório persiste stubs e faz **`ensureImageForDate`** para fetch lazy.

4. **Planet fallback** expoe `source: planet_preview` e `is_ndvi: false` —
   UI rotula como preview RGB, sem mascara verde.

5. Erros HTTP != 404 propagam para o `FutureProvider` (estado `error` no sheet).

## Consequencias

- NDVI funciona para talhoes de consultoria e drawing sem importar
  `consultoria/` dentro de `ndvi/`.
- Historico multi-data e stats NDVI dependem de deploy da Edge Function
  `ndvi-fetch` + secret `SENTINEL_HUB_TOKEN`.
- Testes em `test/modules/ndvi/` cobrem fases 1–3 e contrato em
  `test/supabase/ndvi_fetch_contract_test.dart`.

## Referencias

- ADR-022 — modulo NDVI + `IFieldLookup`
- ADR-024 — `FieldLookupGeofenceAdapter`
