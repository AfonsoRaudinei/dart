# SOLOFORTE — AUDITORIA LOTE 5 — MARKETING, PLANOS, CARTEIRA, PRODUTOR E FEEDBACK

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `marketing`, `planos`, `carteira`, `produtor`, `feedback`  
**Prioridade:** P1  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `lib/modules/marketing/AGENTS.md`
- `lib/modules/planos/AGENTS.md`
- `lib/modules/carteira/AGENTS.md`
- `lib/modules/produtor/AGENTS.md`
- `lib/modules/feedback/AGENTS.md`
- `lib/core/contracts/i_marketing_case_reports_lookup.dart`
- `lib/core/contracts/i_opportunity_lookup.dart`
- `lib/core/contracts/i_producer_invite_writer.dart`
- `lib/core/contracts/i_producer_property_gateway.dart`
- `lib/core/contracts/i_occurrence_access_reader.dart`
- `lib/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart`
- `lib/modules/marketing/data/services/marketing_case_client_id_backfill_service.dart`
- `lib/modules/carteira/data/repositories/carteira_repository_impl.dart`
- `lib/modules/produtor/data/producer_link_repository.dart`
- `lib/modules/feedback/data/repositories/supabase_feedback_repository.dart`

## Limites

- Nao valida Stripe/App Store/assinaturas reais.
- Nao valida RLS publicada de feedback/produtor/marketing.
- Nao valida export HTML visual final.

## Achados

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: lib/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart:140-142
Problema: `resolvedRole` é calculado e não usado.
Risco: Mantém analyzer global falhando e indica que o papel do consultor pode não estar sendo aplicado no bundle exportado.
Direção da correção (conceitual, sem código): Decidir se o papel deve entrar no payload/export ou remover o cálculo; validar HTML/JSON exportado de marketing.
Evidência: `final resolvedRole = ... fallbackConsultantRole;` sem uso posterior.
Validação necessária: flutter analyze lib/modules/marketing/ + teste de export bundle.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/feedback/data/repositories/supabase_feedback_repository.dart:64-73
Problema: Envio de feedback permite `user_id` nulo no payload.
Risco: Se a política RLS exigir usuário autenticado, o insert falha; se a tabela aceitar nulo, feedback pode ficar sem dono e sem isolamento claro.
Direção da correção (conceitual, sem código): Definir contrato: feedback privado exige sessão autenticada antes do envio, ou feedback público deve ter política/tabela explicitamente separada.
Evidência: `'user_id': user?.id`
Validação necessária: teste de envio sem sessão + validação RLS publicada.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/feedback/data/repositories/supabase_feedback_repository.dart:14-21
Problema: Estatísticas de feedback fazem select amplo sem filtro local por `user_id`.
Risco: A segurança depende integralmente da RLS remota; em ambiente com policy incorreta, dados agregados de outros usuários podem vazar.
Direção da correção (conceitual, sem código): Manter RLS como barreira obrigatória e considerar filtro explícito por usuário quando as estatísticas forem user-scoped.
Evidência: `.from('feedback').select('type,module')`
Validação necessária: teste com Supabase local/RLS e usuários distintos.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: D
Localização: lib/modules/marketing/data/services/marketing_case_client_id_backfill_service.dart:41-70
Problema: Backfill de `client_id` preserva valores existentes e marca `synced` como `pending_sync` ao preencher.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter testes de idempotência e de casos ambíguos.
Evidência: se `client_id` existe, item é preservado; quando preenche, `synced` vira `pending_sync`.
Validação necessária: testes de `marketing_case_client_id_resolver`.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: D
Localização: lib/modules/carteira/data/repositories/carteira_repository_impl.dart:461-470
Problema: Hard delete aparece documentado como permitido para `carteira_lancamentos` local-only.
Risco: Sem risco identificado dentro do escopo avaliado, desde que a premissa local-only continue verdadeira.
Direção da correção (conceitual, sem código): Se carteira ganhar sync remoto, converter deleção para soft delete/sync_status antes de publicar.
Evidência: comentário local declara "Hard delete permitido: `carteira_lancamentos` é local-only".
Validação necessária: revisão de schema se carteira virar sincronizável.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: lib/modules/marketing/AGENTS.md + adapter ADR-050
Problema: Integração marketing → relatórios está modelada via contrato `IMarketingCaseReportsLookup`.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter consultoria consumindo apenas contrato em `core/contracts`.
Evidência: `MarketingCaseReportsLookupAdapter implements IMarketingCaseReportsLookup`.
Validação necessária: arch_check.sh.
```

## RESUMO

Lote auditado: 5 — Marketing, Planos, Carteira, Produtor e Feedback  
Bounded contexts: marketing, planos, carteira, produtor, feedback  
Arquivos avaliados: 15  
Total de achados: 6  
Alta severidade: 0  
Média severidade: 3  
Baixa severidade: 3  
Achados que exigem ADR novo: 0  
Achados que dependem de backend/RLS/device/build real: 2  
Nenhuma alteração de código foi feita — apenas diagnóstico.
