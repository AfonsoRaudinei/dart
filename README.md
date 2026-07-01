# SoloForte App

Aplicativo mobile Flutter para **consultoria agrícola de campo** — map-first, offline-first.

## Plataformas

- iOS 15+ · Android 8+ (API 26+)
- **Mobile-only** (Web, Windows, macOS e Linux não são suportados)

## Funcionalidades

- Mapa técnico com talhões e camadas (satélite, terreno, OSM)
- Visitas de campo com geolocalização e geofence
- Ocorrências agronômicas georreferenciadas
- Clientes, fazendas e talhões
- Sync silencioso com Supabase
- 100% operação offline

## Configuração local

```bash
flutter pub get

# Opção A — dart-define inline
flutter run \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY

# Opção B — arquivo (recomendado para release)
cp dart_defines.example.json dart_defines.json
# edite dart_defines.json com a anon key real
flutter run --dart-define-from-file=dart_defines.json
```

> **Importante:** sem `SUPABASE_URL` e `SUPABASE_ANON_KEY` em tempo de compilação, o Supabase **não inicializa** (causa comum de IPA “sem banco”).

## Supabase

1. SQL no Dashboard — [`docs/SUPABASE_MANUAL.md`](docs/SUPABASE_MANUAL.md)
2. Especificação das 8 tabelas — [`docs/SUPABASE_RELATORIO_COMPLETO.md`](docs/SUPABASE_RELATORIO_COMPLETO.md)

Scripts SQL (ordem):

1. `supabase_schema.sql`
2. `supabase/auth_delete_account.sql`
3. `supabase/feedback_table.sql`

## Release (build 153+)

```bash
cp dart_defines.example.json dart_defines.json
# preencher SUPABASE_ANON_KEY

# iOS (macOS + Xcode)
./scripts/build_ipa.sh 153

# Android
./scripts/build_appbundle.sh 153
```

Documentação completa: [`docs/BUILD_RELEASE.md`](docs/BUILD_RELEASE.md)

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| `docs/PRD_RELEASE_LOJAS.md` | PRD completo de release |
| `docs/arquitetura-navegacao.md` | Contrato de navegação (congelado) |
| `docs/FASE1_P0_VALIDACAO.md` | Checklist Fase 1 |
| `docs/FASE2_P1_VALIDACAO.md` | Checklist Fase 2 |
| `docs/FASE3_VALIDACAO.md` | Checklist Fase 3 |
| `docs/store/GUIA_SUBMISSAO.md` | Submissão App Store / Play |

## Testes

```bash
flutter analyze
flutter test
```

CI: `.github/workflows/flutter_ci.yml`
