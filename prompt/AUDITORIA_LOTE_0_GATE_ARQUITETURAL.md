# SOLOFORTE — AUDITORIA LOTE 0 — GATE ARQUITETURAL TRANSVERSAL

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `core`, `ui`, `map`  
**Prioridade:** P0  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `AGENTS.md`
- `lib/core/AGENTS.md`
- `lib/ui/AGENTS.md`
- `lib/modules/map/AGENTS.md`
- `lib/core/router/app_router.dart`
- `lib/core/session/session_controller.dart`
- `lib/core/session/local_session_identity.dart`
- `lib/ui/components/app_shell.dart`
- `lib/ui/components/smart_button.dart`
- `lib/ui/screens/private_map_screen.dart`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`
- `lib/ui/screens/map/widgets/map_performance_hosts.dart`
- `lib/modules/map/presentation/widgets/visit_active_card.dart`
- `lib/ui/components/map/widgets/isolated_marker_layers.dart`

## Arquivos Citados, Mas Nao Auditados Em Profundidade

- `lib/core/contracts/*.dart`
- `lib/core/database/database_helper.dart`
- `lib/ui/components/map/**`
- `test/ui/components/map/**`

## Limites

- Esta auditoria valida arquitetura local por leitura e comandos estáticos.
- Nao valida runtime em device, Supabase real, RLS publicada, assinatura iOS ou TestFlight.
- `./tool/arch_check.sh` foi usado como evidência objetiva de gate arquitetural atual.

## Achados

```yaml
🟡 [Severidade: Média]
Categoria: B
Localização: lib/modules/map/presentation/widgets/visit_active_card.dart:10/26
Problema: O módulo map ainda importa e observa diretamente o controller de presentation de visitas.
Risco: O mapa fica acoplado ao estado interno de visitas; mudanças no controller podem quebrar o card de visita ativa sem passar por contrato estável.
Direção da correção (conceitual, sem código): Manter o mapa consumindo somente contratos neutros de sessão/visita em core/contracts, ou documentar a exceção com plano de remoção da whitelist.
Evidência: "import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';" e "final sessionAsync = ref.watch(visitControllerProvider);"
Validação necessária: arch_check.sh + teste de card de visita ativa no mapa.
```

```yaml
🟡 [Severidade: Média]
Categoria: B
Localização: lib/ui/components/map/widgets/isolated_marker_layers.dart:13-20
Problema: Camada global de UI do mapa importa entidades/providers de consultoria, dashboard, marketing e settings diretamente.
Risco: A UI compartilhada do mapa vira ponto de acoplamento lateral; uma mudança interna de marketing/consultoria/produtor pode quebrar renderização do mapa.
Direção da correção (conceitual, sem código): Concentrar projeções de markers e autorização em providers/adapters de contrato, deixando a camada UI consumir modelos já projetados para mapa.
Evidência: imports diretos de occurrence, marketing case, marketing providers e user profile provider no mesmo widget de camada.
Validação necessária: arch_check.sh + testes de marker layers.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: A
Localização: lib/core/session/session_controller.dart:36-51
Problema: Nenhum vazamento óbvio de subscription de auth foi encontrado no provider de sessão.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Nenhuma.
Evidência: `_authSubscription` é cancelada em `ref.onDispose`.
Validação necessária: teste de ciclo de login/logout.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: lib/core/router/app_router.dart:60-141
Problema: Nenhuma sub-rota sob `/map` foi encontrada na configuração principal do router.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Nenhuma.
Evidência: `/map` aparece como rota singleton para `PrivateMapBootstrapScreen`.
Validação necessária: arch_check.sh.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: C
Localização: lib/ui/screens/private_map_screen.dart
Problema: A tela principal do mapa não ultrapassa o limite de 900 linhas definido pelo gate.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Nenhuma.
Evidência: `wc -l` retornou 694 linhas para `private_map_screen.dart`.
Validação necessária: nenhuma.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: D
Localização: lote inteiro
Problema: Nenhum secret hardcoded foi identificado nesta leitura de Lote 0.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter validação por busca automatizada antes de releases.
Evidência: leitura focada de router, session, shell e mapa.
Validação necessária: validação secret-safe de build/release quando houver IPA.
```

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: validação global
Problema: O gate arquitetural passa, mas o analyzer global e a suíte global não estão limpos no checkout atual.
Risco: Achados reais de outros módulos podem mascarar regressões do gate transversal.
Direção da correção (conceitual, sem código): Tratar analyzer/test como trilhas separadas do arch_check e corrigir por módulo, sem misturar com este relatório.
Evidência: `arch_check.sh` passou; `flutter analyze lib/` apontou 14 issues; `flutter test` terminou com 18 falhas e 1 skip.
Validação necessária: flutter analyze lib/ + flutter test após correções por lote.
```

## RESUMO

Lote auditado: 0 — Gate Arquitetural Transversal  
Bounded contexts: core, ui, map  
Arquivos avaliados: 14  
Total de achados: 7  
Alta severidade: 0  
Média severidade: 3  
Baixa severidade: 4  
Achados que exigem ADR novo: 0, mas 2 dependem de remover/regularizar whitelists atuais  
Achados que dependem de backend/RLS/device/build real: 1  
Nenhuma alteração de código foi feita — apenas diagnóstico.
