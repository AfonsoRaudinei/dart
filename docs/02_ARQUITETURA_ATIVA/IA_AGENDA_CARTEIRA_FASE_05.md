# IA Agenda + Carteira — Fase 05 (Rollout + Telemetria + Hardening)

Status: **Concluída**  
Data: 2026-04-15

## Objetivo da fase

Endurecer a operação da IA Agenda + Carteira para produção com:

- rollout controlado por feature flag no app
- telemetria de uso e erro no fluxo IA
- kill switch e rollout percentual no backend
- validações defensivas de payload/policy

## Entregáveis implementados

- rollout no app por feature flag `agenda_ai_v1`:
  - [feature_flag_providers.dart](../../../lib/core/feature_flags/feature_flag_providers.dart)
  - [feature_flag_backend_adapter.dart](../../../lib/core/feature_flags/feature_flag_backend_adapter.dart)
  - [agenda_month_page.dart](../../../lib/modules/agenda/presentation/pages/agenda_month_page.dart)

- telemetria de produto para IA:
  - [feature_flag_analytics.dart](../../../lib/core/feature_flags/feature_flag_analytics.dart)
  - [agenda_ai_sheet.dart](../../../lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart)

- hardening backend da edge function:
  - [index.ts](../../../supabase/functions/agenda-ai-recommend/index.ts)

## O que mudou na prática

1. O ícone IA da Agenda só aparece quando `agenda_ai_v1` está habilitada para o usuário.
2. A abertura da IA, carregamento de recomendações, chat e criação de visita agora geram telemetria.
3. A edge function ganhou:
   - `AGENDA_AI_ENABLED` (kill switch)
   - `AGENDA_AI_ROLLOUT_PERCENT` (rollout determinístico por `consultantId`)
   - sanitização de payload (`opportunities`, `policy`, geolocalização)
   - telemetria estruturada com `requestId`, `outcome` e `durationMs`
4. Prompt da explicação IA passa a considerar `chatMessage` quando enviada pelo usuário.

## Variáveis de ambiente (Fase 05)

- `AGENDA_AI_ENABLED=true|false` (default: `true`)
- `AGENDA_AI_ROLLOUT_PERCENT=0..100` (default: `100`)
- `OPENROUTER_API_KEY` (opcional)
- `OPENROUTER_MODEL` (opcional)

## Revisão da fase

Checklist:

- [x] rollout por flag aplicado no app
- [x] telemetria de uso/erro aplicada no fluxo IA
- [x] kill switch backend aplicado
- [x] rollout percentual backend aplicado
- [x] validação defensiva e sanitização de entrada aplicada

## Go/No-Go

Pronto para operação controlada em produção, com expansão gradual via `agenda_ai_v1` + `AGENDA_AI_ROLLOUT_PERCENT`.
