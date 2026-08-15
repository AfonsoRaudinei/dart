# SOLOFORTE — PLANO DE CORRECAO DOS ACHADOS DA AUDITORIA POR LOTES

**Modo deste documento:** plano de execucao. Nenhum codigo foi alterado por este plano.  
**Base:** auditorias `AUDITORIA_LOTE_0` a `AUDITORIA_LOTE_6`.  
**Data:** 2026-08-10  
**Regra de execucao:** corrigir por fase, validar, revisar diff e so entao seguir para a fase seguinte.

---

## Objetivo

Eliminar os achados citados nas auditorias por lote sem misturar refatoracao oportunista, preservando:

- Map-First e `/map` singleton.
- Bounded contexts e comunicacao por `core/contracts`.
- Persistencia offline-first com `user_id` e `sync_status`.
- FAB global imutavel.
- Worktree sujo preexistente preservado, especialmente `.flutter-plugins-dependencies`.

---

## Ordem Executiva

1. **Fase 0 — Preparacao e baseline**
2. **Fase 1 — Falhas vermelhas e analyzer de baixo risco**
3. **Fase 2 — Contratos funcionais de ocorrencia e agenda-visitas**
4. **Fase 3 — Identidade, logout, sync remoto e RLS**
5. **Fase 4 — Logs, privacidade e localizacao**
6. **Fase 5 — Acoplamentos whitelisted do mapa/UI**
7. **Fase 6 — Performance e estado de drawing/GPS**
8. **Fase 7 — Settings/Riverpod legado e higiene modular**
9. **Fase 8 — Validacao final e registro**

---

## Fase 0 — Preparacao e Baseline

**Objetivo:** congelar estado atual antes de tocar código.

**Acoes:**

- Ler `AGENTS.md`, `lib/core/AGENTS.md`, `lib/ui/AGENTS.md` e AGENTS do modulo afetado em cada fase.
- Rodar e salvar resultado de:
  - `git status --porcelain=v1 -uall`
  - `./tool/arch_check.sh`
  - `flutter analyze lib/`
  - testes focados já vermelhos
- Confirmar que `.flutter-plugins-dependencies` e qualquer outro arquivo sujo preexistente nao sera revertido nem stageado por engano.

**Criterio de aceite:**

- Baseline documentado.
- Lista de arquivos sujos preexistentes separada dos arquivos que serao alterados.

---

## Fase 1 — Falhas Vermelhas e Analyzer De Baixo Risco

**Prioridade:** P0  
**Origem:** Lotes 0, 2, 3, 4, 5, 6

### 1.1 Occurrence draft: `setState` em extension

**Arquivos provaveis:**

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_draft.dart`
- `test/modules/consultoria/occurrences/occurrence_draft_restore_test.dart`

**Direcao:**

- Mover a mutacao de estado para uma API pertencente ao `State` real ou outro ponto aceito pelo analyzer.
- Preservar o comportamento de restore/persist/clear de rascunho keyed por pin.
- Nao alterar UX do sheet nesta fase.

**Validacao focada:**

- `flutter analyze lib/modules/consultoria/occurrences/presentation/widgets/`
- `flutter test test/modules/consultoria/occurrences/occurrence_draft_restore_test.dart --reporter compact`

### 1.2 Analyzer simples

**Arquivos provaveis:**

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart`
- `lib/ui/screens/map/widgets/map_performance_hosts.dart`
- `lib/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart`
- `lib/modules/consultoria/quick_photo/data/quick_photo_repository.dart`
- `lib/ui/components/map/map_bottom_sheet.dart`
- `lib/ui/components/side_menu_overlay_sections.dart`

**Direcao:**

- Resolver import não usado, import duplicado, `@override` ausente e `resolvedRole` sem uso.
- Para `resolvedRole`, decidir se ele deve entrar no export bundle ou se o cálculo deve sair. Validar export de marketing.
- Tratar `prefer_const` como limpeza de baixo risco somente se o diff ficar pequeno.

**Validacao focada:**

- `flutter analyze lib/`

**Criterio de aceite da Fase 1:**

- Analyzer sem os 14 issues atuais ou com justificativa explicita para qualquer item remanescente.
- Teste de rascunho de ocorrência passando.

---

## Fase 2 — Contratos Funcionais De Ocorrencia e Agenda-Visitas

**Prioridade:** P0  
**Origem:** Lotes 2, 4, 6

### 2.1 StartEventUseCase e espelho em visit_sessions

**Arquivos provaveis:**

- `lib/modules/agenda/domain/use_cases/start_event_use_case.dart`
- `test/modules/agenda/use_cases/start_event_use_case_test.dart`
- `lib/core/contracts/i_visit_session_writer.dart`
- adapters de escrita em `visitas/infra`, se necessário

**Decisao necessaria antes de editar:**

- Regra A: falha no espelho é recuperável e nao impede evento/sessao da agenda.
- Regra B: falha no espelho exige rollback transacional.

**Direcao recomendada:**

- Seguir o contrato já declarado pelo teste atual: falha no espelho nao impede persistencia da agenda.
- Registrar falha de espelho de modo recuperável e rastreável, sem relançar depois de persistir estado local.

**Validacao focada:**

- `flutter test test/modules/agenda/use_cases/start_event_use_case_test.dart --reporter compact`
- testes de visitas/agenda relacionados ao espelho.

### 2.2 Rascunho e cache de ocorrências

**Arquivos provaveis:**

- `lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart`
- testes de occurrence sync/cache, criar se faltar cobertura.

**Direcao:**

- Provar por teste que hard delete local em cache legado nunca apaga ocorrência autoral ou pendente.
- Separar cache derivado/remoto de registro criado pelo usuário.

**Validacao focada:**

- teste de cache revogado versus ocorrência própria `pending_sync`/`local_only`.

**Criterio de aceite da Fase 2:**

- Testes vermelhos de agenda e ocorrência passam.
- Sem nova violação de bounded context.

---

## Fase 3 — Identidade, Logout, Sync Remoto e RLS

**Prioridade:** P0/P1  
**Origem:** Lotes 1, 2, 5, 6

### 3.1 Logout transacional

**Arquivos provaveis:**

- `lib/core/session/session_controller.dart`
- `lib/core/session/local_session_identity.dart`
- testes de sessão/logout.

**Direcao:**

- Evitar limpar identidade local e invalidar providers de forma irreversível antes de saber se `signOut` concluiu.
- Definir comportamento em falha de `signOut`: manter sessão autenticada, estado de erro, ou retry controlado.

**Validacao focada:**

- teste de logout com `signOut` falhando.
- teste de logout bem-sucedido preservando SQLite local.

### 3.2 Identidade remota versus fallback local

**Arquivos provaveis:**

- `lib/core/session/local_session_identity.dart`
- `lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart`
- sync services que fazem push remoto.

**Direcao:**

- Usar identidade autenticada atual para operação remota.
- Manter `lastKnown` apenas para leitura local em bootstrap/offline, não para push remoto.

**Validacao focada:**

- teste com `SessionUnknown`, `SessionPublic` e troca de usuário.

### 3.3 Feedback e RLS

**Arquivos provaveis:**

- `lib/modules/feedback/data/repositories/supabase_feedback_repository.dart`
- testes de feedback repository.
- `docs/SUPABASE_MANUAL.md` ou scripts RLS, se escopo aprovado.

**Direcao:**

- Decidir se feedback exige usuário autenticado.
- Se sim, bloquear envio sem sessão antes do insert.
- Se não, documentar e separar policy/tabela pública.
- Para estatísticas, decidir se são globais, admin-only ou user-scoped; não depender só de suposição de RLS.

**Validacao focada:**

- teste de envio sem sessão.
- validação Supabase local/RLS com dois usuários, quando ambiente estiver disponível.

**Criterio de aceite da Fase 3:**

- Nenhum push remoto usa fallback local indevido.
- Logout tem teste de falha.
- Feedback tem contrato claro para usuário nulo e estatísticas.

---

## Fase 4 — Logs, Privacidade e Localizacao

**Prioridade:** P1  
**Origem:** Lotes 1, 3, 4

**Arquivos provaveis:**

- `lib/core/utils/app_logger.dart`
- `lib/modules/auth/services/auth_service.dart`
- `lib/modules/clima/presentation/providers/clima_providers.dart`
- `lib/modules/agenda/domain/use_cases/complete_event_use_case.dart`
- `lib/modules/agenda/domain/use_cases/cancel_event_use_case.dart`

**Direcao:**

- Trocar `debugPrint` direto por logging central sanitizado.
- Evitar registrar coordenadas precisas em texto, mesmo em debug/profile.
- Evitar anexar erro bruto de auth/storage quando puder conter URL, path, id ou payload.
- Confirmar que persistência de erro redige email, token, telefone, UUID e coordenadas.

**Validacao focada:**

- busca por `debugPrint(` em `lib/`.
- teste unitário de sanitização do `AppLogger`, se não existir.
- revisão manual de logs em build debug/profile para clima/auth.

**Criterio de aceite:**

- Zero `debugPrint` direto em domínio.
- Nenhum log novo expõe coordenada precisa, token, email, telefone ou UUID.

---

## Fase 5 — Acoplamentos Whitelisted Do Mapa/UI

**Prioridade:** P1  
**Origem:** Lotes 0, 3, 6

**Arquivos provaveis:**

- `lib/modules/map/presentation/widgets/visit_active_card.dart`
- `lib/ui/components/map/widgets/isolated_marker_layers.dart`
- `lib/ui/components/map/widgets/selected_talhao_card.dart`
- `lib/ui/components/map/widgets/producer_map_context_card.dart`
- providers/adapters em `core/contracts/`
- `tool/arch_check.sh`, apenas se remover whitelist já validada.

**Direcao:**

- Remover `map -> visitas/presentation` direto do card de visita ativa.
- Projetar dados necessários do mapa por contratos ou providers neutros.
- Reduzir imports diretos de `ui/components/map` para marketing/consultoria/produtor.
- Cada remoção deve ser pequena e coberta por teste de widget/provider.

**Nao fazer nesta fase:**

- Nao criar rotas novas.
- Nao reescrever o mapa.
- Nao mudar FAB/global shell.

**Validacao focada:**

- `./tool/arch_check.sh`
- testes de marker layers.
- teste de card de visita ativa no mapa.

**Criterio de aceite:**

- Whitelist reduzida ou removida com teste.
- Arch check permanece verde.

---

## Fase 6 — Performance e Estado De Drawing/GPS

**Prioridade:** P1  
**Origem:** Lote 3

**Arquivos provaveis:**

- `lib/ui/screens/map/widgets/map_performance_hosts.dart`
- `lib/modules/drawing/presentation/controllers/drawing_controller.dart`
- `lib/modules/drawing/presentation/providers/gps_walk_providers.dart`
- `lib/modules/drawing/domain/services/gps_tracking_service.dart`
- testes de drawing/GPS walk.

**Direcao:**

- Remover sincronização de estado acionada dentro de build/listenable visual.
- Criar listener/controlador dedicado para sincronizar `DrawingController` e `gpsWalkProvider`.
- Manter `DrawingController` como exceção legada, mas reduzir responsabilidade por extrações pequenas e testadas.
- Não migrar o controller inteiro para Riverpod em uma única etapa.

**Validacao focada:**

- testes de GPS walk com múltiplos pontos.
- testes de drawing existentes.
- perfilamento em device quando possível.

**Criterio de aceite:**

- Sem ciclo de `addPostFrameCallback` dentro de build para sincronização de estado.
- Drawing tests passam.

---

## Fase 7 — Settings/Riverpod Legado e Higiene Modular

**Prioridade:** P2/P1 controlado  
**Origem:** Lote 1

**Arquivos provaveis:**

- `lib/modules/settings/presentation/providers/settings_providers.dart`
- ADR-044
- testes de settings/profile.

**Direcao:**

- Confirmar se `ProfileNotifier`, `ReportBrandingNotifier` e `ThemeNotifier` estão na whitelist ADR-044.
- Se estiverem, registrar como dívida controlada.
- Se não estiverem, planejar migração incremental para Riverpod moderno por provider, começando pelo menor risco.

**Validacao focada:**

- `flutter analyze lib/modules/settings/`
- testes de profile/branding/theme.

**Criterio de aceite:**

- Estado legado classificado: permitido por ADR ou com plano de migração.

---

## Fase 8 — Validacao Final e Registro

**Objetivo:** fechar a correção com provas distintas.

**Gates obrigatorios:**

- `./tool/arch_check.sh`
- `flutter analyze lib/`
- testes focados de cada fase alterada
- `flutter test` global, se o tempo permitir e após estabilizar testes focados

**Checklist final:**

- [ ] Nenhum arquivo fora do escopo foi alterado.
- [ ] `.flutter-plugins-dependencies` preexistente preservado fora do stage, salvo decisão explícita.
- [ ] Arch check verde.
- [ ] Analyzer sem issues novos.
- [ ] Testes vermelhos citados na auditoria corrigidos.
- [ ] Logs sensíveis revisados.
- [ ] Riscos dependentes de RLS/device marcados como não provados se não forem validados em ambiente real.

---

## Mapa De Achados Para Fases

| Achado | Origem | Fase |
|---|---:|---:|
| `setState` em extension de ocorrência draft | Lote 2 | 1 |
| teste de rascunho de ocorrência falhando | Lote 2/6 | 1/2 |
| import não usado em occurrence form | Lote 2 | 1 |
| import duplicado em map performance host | Lote 3 | 1 |
| `resolvedRole` não usado em marketing export | Lote 5 | 1 |
| falha de espelho agenda-visitas relançada após persistir | Lote 4/6 | 2 |
| logout limpa identidade antes de `signOut` concluir | Lote 1 | 3 |
| sync remoto usando fallback de `LocalSessionIdentity` | Lote 2/6 | 3 |
| feedback com `user_id` nulo e stats amplas | Lote 5/6 | 3 |
| logs com coordenadas precisas | Lote 3 | 4 |
| `debugPrint` direto em use cases | Lote 4 | 4 |
| logs de auth/storage com erro bruto | Lote 1 | 4 |
| `map -> visitas/presentation` direto | Lote 0/6 | 5 |
| `ui/components/map -> marketing/consultoria/produtor` direto | Lote 0/6 | 5 |
| sync GPS por `addPostFrameCallback` em build | Lote 3/6 | 6 |
| `DrawingController` grande/legado | Lote 3/6 | 6 |
| Settings com `StateNotifierProvider` legado | Lote 1 | 7 |

---

## Sequencia Recomendada De Commits

1. `fix(consultoria): estabiliza rascunho de ocorrencia`
2. `fix(agenda): trata falha de espelho de visita`
3. `chore(analyzer): limpa imports e avisos focados`
4. `fix(session): torna logout e sync remoto seguros por identidade`
5. `fix(feedback): explicita contrato de usuario e stats`
6. `chore(logging): sanitiza logs de dominio e localizacao`
7. `refactor(map): reduz acoplamentos whitelisted por contratos`
8. `refactor(drawing): isola sincronizacao GPS fora do build`
9. `docs(auditoria): registra validacao final`

Cada commit deve ser feito com `git add` por arquivo, nunca `git add .`.
