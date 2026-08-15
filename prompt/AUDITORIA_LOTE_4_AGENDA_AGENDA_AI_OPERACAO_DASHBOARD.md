# SOLOFORTE — AUDITORIA LOTE 4 — AGENDA, AGENDA AI, OPERACAO E DASHBOARD

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `agenda`, `agenda_ai`, `operacao`, `dashboard`  
**Prioridade:** P1  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `lib/modules/agenda/AGENTS.md`
- `lib/modules/agenda_ai/AGENTS.md`
- `lib/modules/operacao/AGENTS.md`
- `lib/modules/dashboard/AGENTS.md`
- `lib/core/contracts/i_agenda_session_bridge.dart`
- `lib/core/contracts/i_agenda_observable.dart`
- `lib/core/contracts/i_visit_session_lookup.dart`
- `lib/modules/agenda/domain/use_cases/start_event_use_case.dart`
- `lib/modules/agenda/domain/use_cases/complete_event_use_case.dart`
- `lib/modules/agenda/domain/use_cases/cancel_event_use_case.dart`
- `lib/modules/agenda/presentation/pages/agenda_day_page.dart`
- `test/modules/agenda/use_cases/start_event_use_case_test.dart`
- `lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart`
- `lib/modules/dashboard/providers/location_providers.dart`

## Limites

- Nao valida notificações locais no device.
- Nao valida Agenda AI com dados reais longos.
- `operacao/` está em fase sem código Dart ativo; a auditoria ali é estrutural.

## Achados

```yaml
🔴 [Severidade: Alta]
Categoria: A
Localização: lib/modules/agenda/domain/use_cases/start_event_use_case.dart:64-86
Problema: O use case persiste evento e sessão da agenda, tenta criar o espelho em visitas e re-lança a falha do espelho.
Risco: O estado local pode ficar parcialmente persistido e o fluxo retorna erro ao usuário; a própria suíte espera que falha no espelho não impeça a persistência da sessão da agenda.
Direção da correção (conceitual, sem código): Definir a semântica oficial: ou rollback transacional completo, ou falha de espelho recuperável com pendência explícita. O comportamento precisa casar com o teste e com ADR-048.
Evidência: `await _repository.updateEvent(updatedEvent); await _repository.saveSession(session);` seguido de `Error.throwWithStackTrace(error, stackTrace);`
Validação necessária: `test/modules/agenda/use_cases/start_event_use_case_test.dart`.
```

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: test/modules/agenda/use_cases/start_event_use_case_test.dart:107-118
Problema: O teste documenta que a falha no espelho não deve impedir a sessão da agenda, mas o código atual não cumpre esse contrato.
Risco: Regressão de regra de domínio fica explícita e mantém a suíte global com falha.
Direção da correção (conceitual, sem código): Atualizar código ou teste somente depois de decidir a regra de domínio; não manter contrato contraditório.
Evidência: teste "falha no espelho não impede persistência da sessão da agenda".
Validação necessária: teste focado de start event.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/agenda/domain/use_cases/complete_event_use_case.dart:68-75 e cancel_event_use_case.dart:79-86
Problema: Use cases de domínio usam `debugPrint` direto com sessionId, erro e stackTrace.
Risco: Viola a política de logging centralizado e pode expor identificadores/stack em ambientes de debug/profile.
Direção da correção (conceitual, sem código): Usar logging sanitizado e consistente com `AppLogger`, sem despejar stack completo em texto de domínio.
Evidência: `debugPrint('CompleteEventUseCase: falha ao encerrar espelho $sessionId — $error\n$stackTrace')`
Validação necessária: busca por `debugPrint` + teste de logging, se houver.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: lib/modules/operacao/AGENTS.md
Problema: `operacao/` está corretamente declarado como Fase 0 sem código Dart ativo.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Exigir ADR novo antes de adicionar domínio operacional.
Evidência: AGENTS do módulo declara "diretório sem código Dart ativo".
Validação necessária: arch_check.sh.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: C
Localização: lib/modules/agenda/presentation/pages/agenda_day_page.dart:162-175
Problema: Lista diária usa `ListView.builder`, adequado para lista potencialmente longa.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Nenhuma.
Evidência: `_buildEventList` usa `ListView.builder`.
Validação necessária: teste widget de agenda diária.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: E
Localização: lib/modules/agenda/presentation/pages/agenda_day_page.dart:170-171
Problema: Tap de evento diário ainda contém TODO sem ação.
Risco: Usuário pode tocar em evento e nada acontecer, reduzindo testabilidade do fluxo de detalhe.
Direção da correção (conceitual, sem código): Definir se o tap deve navegar por rota existente de detalhe ou permanecer inativo com affordance visual coerente.
Evidência: `onTap: () { // TODO: abrir detalhes do evento }`
Validação necessária: teste widget/navegação da agenda diária.
```

## RESUMO

Lote auditado: 4 — Agenda, Agenda AI, Operacao e Dashboard  
Bounded contexts: agenda, agenda_ai, operacao, dashboard  
Arquivos avaliados: 14  
Total de achados: 6  
Alta severidade: 1  
Média severidade: 2  
Baixa severidade: 3  
Achados que exigem ADR novo: 0, salvo mudança de semântica ADR-048  
Achados que dependem de backend/RLS/device/build real: 1  
Nenhuma alteração de código foi feita — apenas diagnóstico.
