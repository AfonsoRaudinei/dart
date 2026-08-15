# SOLOFORTE — AUDITORIA LOTE 2 — CONSULTORIA, RELATORIOS E VISITAS

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `consultoria`, `visitas`, `core/contracts`  
**Prioridade:** P0/P1  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `lib/modules/consultoria/AGENTS.md`
- `lib/modules/visitas/AGENTS.md`
- `lib/core/contracts/i_client_lookup.dart`
- `lib/core/contracts/i_farm_lookup.dart`
- `lib/core/contracts/i_field_lookup.dart`
- `lib/core/contracts/i_visit_session_lookup.dart`
- `lib/core/contracts/i_visit_client_lookup.dart`
- `lib/core/contracts/i_report_writer.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_draft.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart`
- `lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart`
- `lib/modules/visitas/presentation/controllers/geofence_controller.dart`
- `lib/modules/visitas/presentation/controllers/visit_controller.dart`
- `lib/modules/visitas/data/repositories/visit_sync_service.dart`

## Limites

- Nao valida HTML final renderizado em navegador/PDF.
- Nao valida RLS publicada.
- Nao valida geofence em foreground no device.

## Achados

```yaml
🔴 [Severidade: Alta]
Categoria: A
Localização: lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_draft.dart:65-73/114-116
Problema: O código chama `setState` dentro de extensão privada do State; o analyzer marca `invalid_use_of_protected_member` e o teste de restauração de rascunho está falhando.
Risco: Rascunhos de ocorrência podem não restaurar corretamente e a suíte global fica vermelha em fluxo crítico de campo.
Direção da correção (conceitual, sem código): Reposicionar a mutação de estado em método pertencente ao State ou encapsular a atualização por uma API interna segura, mantendo persistência do rascunho keyed por pin.
Evidência: `setState(() => _selectedClient = selected);` e `setState(fn);`
Validação necessária: flutter analyze lib/ + `test/modules/consultoria/occurrences/occurrence_draft_restore_test.dart`.
```

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: lib/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart:2
Problema: Import de `image_picker` está presente sem uso.
Risco: Mantém analyzer global falhando e reduz confiança no gate de release.
Direção da correção (conceitual, sem código): Remover dependência não usada ou mover uso real para o arquivo correto, preservando o contrato do widget.
Evidência: `import 'package:image_picker/image_picker.dart';`
Validação necessária: flutter analyze lib/modules/consultoria/.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart:45-75
Problema: Push remoto de ocorrência depende de `LocalSessionIdentity.resolveUserId()` e marca local como `synced` após upsert; se a identidade fallback estiver incorreta, o payload pode ser enviado com proprietário errado.
Risco: Em cenários de bootstrap/logout mal sequenciados, dados de ocorrência podem ficar associados ao usuário errado ou falhar por RLS.
Direção da correção (conceitual, sem código): Garantir que sync remoto use identidade autenticada atual, não fallback, e manter fallback apenas para leitura local em SessionUnknown.
Evidência: `final userId = LocalSessionIdentity.resolveUserId();` seguido de `upsert(payload)` e update local para `synced`.
Validação necessária: teste de sync com sessão pública, SessionUnknown e usuário autenticado diferente.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart:222-233
Problema: Cache legado compartilhado é removido por hard delete local para registros `synced`.
Risco: Se a classificação `synced` estiver errada ou se o registro tiver sido editado localmente fora do status esperado, pode haver perda local silenciosa.
Direção da correção (conceitual, sem código): Confirmar por teste que somente cache derivado/remoto é removido, nunca registro autoral ou pendente.
Evidência: `await db.delete('occurrences', where: ... "AND sync_status = 'synced'")`
Validação necessária: teste de cache revogado versus ocorrência própria pending/local.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: lib/modules/visitas/AGENTS.md + leitura de controllers
Problema: Visitas mantém regra local declarada de comunicação por contratos.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter arch_check como gate obrigatório.
Evidência: AGENTS de visitas proíbe imports diretos de drawing/consultoria fora de exceções.
Validação necessária: arch_check.sh.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: C
Localização: lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart
Problema: Arquivo está exatamente no limite de 900 linhas.
Risco: Ainda passa no gate, mas qualquer adição tende a violar governança de tamanho.
Direção da correção (conceitual, sem código): Manter novas responsabilidades em partes/widgets já extraídos, sem voltar a crescer o arquivo principal.
Evidência: `wc -l` retornou 900 linhas.
Validação necessária: arch_check.sh.
```

## RESUMO

Lote auditado: 2 — Consultoria, Relatorios e Visitas  
Bounded contexts: consultoria, visitas, core/contracts  
Arquivos avaliados: 15  
Total de achados: 6  
Alta severidade: 1  
Média severidade: 3  
Baixa severidade: 2  
Achados que exigem ADR novo: 0  
Achados que dependem de backend/RLS/device/build real: 2  
Nenhuma alteração de código foi feita — apenas diagnóstico.
