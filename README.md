# SoloForte App

Aplicativo mobile Flutter para **consultoria agrícola de campo** — map-first, offline-first.

## Plataformas

- iOS 15+
- Android 8+ (API 26+)

## Funcionalidades

- Mapa técnico com talhões e camadas (satélite, terreno, OSM)
- Visitas de campo com geolocalização e geofence
- Ocorrências agronômicas georreferenciadas
- Clientes, fazendas e talhões
- Sync silencioso com Supabase
- 100% operação offline

## Configuração

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

## Supabase

Executar no SQL Editor, nesta ordem:

1. `supabase_schema.sql`
2. `supabase/auth_delete_account.sql`
3. `supabase/feedback_table.sql`

## Release

- Build: `docs/BUILD_RELEASE.md`
- Metadados lojas: `docs/store/METADADOS_LOJAS.md`
- Submissão: `docs/store/GUIA_SUBMISSAO.md`
- Smoke test: `docs/SMOKE_TEST_CHECKLIST.md`

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| `docs/PRD_RELEASE_LOJAS.md` | PRD completo de release |
| `docs/arquitetura-navegacao.md` | Contrato de navegação (congelado) |
| `docs/FASE1_P0_VALIDACAO.md` | Checklist Fase 1 |
| `docs/FASE2_P1_VALIDACAO.md` | Checklist Fase 2 |
| `docs/FASE3_VALIDACAO.md` | Checklist Fase 3 |

## Testes

```bash
flutter analyze
flutter test
```

CI: `.github/workflows/flutter_ci.yml`
