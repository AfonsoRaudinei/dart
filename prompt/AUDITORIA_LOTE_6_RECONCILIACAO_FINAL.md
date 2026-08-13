# SOLOFORTE — AUDITORIA LOTE 6 — RECONCILIACAO FINAL CROSS-MODULE

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** todos  
**Prioridade:** P1  
**Data:** 2026-08-10  

## Entradas Usadas

- `prompt/AUDITORIA_LOTE_0_GATE_ARQUITETURAL.md`
- `prompt/AUDITORIA_LOTE_1_AUTH_SESSAO_SETTINGS_PUBLIC.md`
- `prompt/AUDITORIA_LOTE_2_CONSULTORIA_RELATORIOS_VISITAS.md`
- `prompt/AUDITORIA_LOTE_3_DRAWING_MAP_NDVI_CLIMA.md`
- `prompt/AUDITORIA_LOTE_4_AGENDA_AGENDA_AI_OPERACAO_DASHBOARD.md`
- `prompt/AUDITORIA_LOTE_5_MARKETING_PLANOS_CARTEIRA_PRODUTOR_FEEDBACK.md`
- Resultado local de `./tool/arch_check.sh`
- Resultado local de `flutter analyze lib/`
- Resultado local de `flutter test`

## Estado Dos Gates No Checkout Auditado

- `./tool/arch_check.sh`: aprovado.
- `flutter analyze lib/`: falhou com 14 issues.
- `flutter test`: falhou com 18 falhas e 1 skip.
- Worktree já estava sujo em `.flutter-plugins-dependencies`; este arquivo nao foi alterado pela auditoria.

## Achados Consolidados

```yaml
🔴 [Severidade: Alta]
Categoria: A
Localização: Lote 2 + Lote 4
Problema: Existem falhas funcionais cobertas por testes em ocorrência draft e início de evento/espelho de visita.
Risco: Dois fluxos de campo podem falhar em uso real: restauração de rascunho de ocorrência e início de evento com espelho em visit_sessions.
Direção da correção (conceitual, sem código): Corrigir primeiro os contratos testados que já estão vermelhos, sem misturar com refatorações estruturais.
Evidência: `occurrence_draft_restore_test` e `start_event_use_case_test` falharam na suíte global.
Validação necessária: testes focados desses dois arquivos + flutter test.
```

```yaml
🟡 [Severidade: Média]
Categoria: B
Localização: Lote 0 + Lote 3
Problema: O arch_check passa, mas depende de whitelists temporárias para acoplamentos laterais do mapa/UI.
Risco: A arquitetura parece verde no gate, mas ainda contém dependências diretas que podem bloquear evolução segura dos bounded contexts.
Direção da correção (conceitual, sem código): Tratar whitelists como dívida controlada, com lote próprio de remoção por contrato/adapters.
Evidência: `map -> visitas` e `ui/components/map -> marketing/consultoria/produtor` aparecem como dívidas whitelisted no gate.
Validação necessária: arch_check.sh após cada remoção de whitelist.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: Lote 1 + Lote 2 + Lote 5
Problema: Identidade de usuário e RLS aparecem como ponto comum de risco em logout, sync de ocorrência e feedback.
Risco: Um bug de sessão ou policy pode causar falha de sync, dados sem dono ou acesso indevido entre usuários.
Direção da correção (conceitual, sem código): Separar identidade autenticada para operações remotas de fallback local para bootstrap/offline, e validar RLS com usuários distintos.
Evidência: uso de `LocalSessionIdentity.resolveUserId()` em sync remoto e payload de feedback com `user?.id`.
Validação necessária: suíte Supabase local/RLS com dois usuários.
```

```yaml
🟡 [Severidade: Média]
Categoria: C
Localização: Lote 0 + Lote 3
Problema: A performance do mapa melhorou por isolamento, mas ainda há sincronização de estado em build/listener e arquivos muito grandes.
Risco: GPS/desenho/mapa podem ter regressões intermitentes de rebuild ou estado divergente sob uso contínuo em campo.
Direção da correção (conceitual, sem código): Priorizar testes de stress/rebuild e extrações pequenas em DrawingController, sem trocar a arquitetura de uma vez.
Evidência: `DrawingController` com 1736 linhas e `addPostFrameCallback` dentro de `ListenableBuilder`.
Validação necessária: teste de GPS walk/desenho + perfilamento em device.
```

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: validação global
Problema: Analyzer e testes globais não estão limpos, apesar de `arch_check.sh` verde.
Risco: Release pode ser tratado como arquiteturalmente aprovado mesmo com regressões funcionais e warnings relevantes.
Direção da correção (conceitual, sem código): Usar três gates separados no plano de correção: arch_check, analyzer e testes focados/globais.
Evidência: `flutter analyze lib/` retornou 14 issues; `flutter test` terminou com `+1287 ~1 -18`.
Validação necessária: repetir gates após correção dos lotes 2, 3, 4 e 5.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: Lote 5
Problema: Marketing possui adapter explícito para relatórios via contrato ADR-050.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Preservar esse padrão ao corrigir exports.
Evidência: `MarketingCaseReportsLookupAdapter implements IMarketingCaseReportsLookup`.
Validação necessária: arch_check.sh + testes de relatórios gerados.
```

## Ordem Recomendada De Correcao Posterior

1. Corrigir falhas vermelhas existentes em `occurrence_creation_sheet_draft` e `start_event_use_case`.
2. Limpar analyzer de baixo risco: duplicate import, unused import e unused local variable.
3. Revisar identidade remota versus fallback local em sync/logout/feedback.
4. Reduzir acoplamentos whitelisted do mapa/UI por contratos.
5. Endurecer logs com localização, IDs e stack traces.
6. Planejar decomposição incremental de `DrawingController` e telas/arquivos no limite.

## RESUMO

Lote auditado: 6 — Reconciliacao Final Cross-Module  
Bounded contexts: todos  
Arquivos avaliados: relatórios dos lotes 0 a 5 + gates locais  
Total de achados: 6  
Alta severidade: 1  
Média severidade: 4  
Baixa severidade: 1  
Achados que exigem ADR novo: 0 imediato; possível ADR se mudar semântica de espelho agenda-visitas  
Achados que dependem de backend/RLS/device/build real: 3  
Nenhuma alteração de código foi feita — apenas diagnóstico.
