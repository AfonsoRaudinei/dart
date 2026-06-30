# FIX — marketing/ — Publicar: _isLoading stuck + sheet não fecha no erro
**Agente:** Engenheiro Sênior Flutter/Dart — Clean Architecture Riverpod
**Módulo:** marketing/
**Objetivo:** Corrigir _isLoading permanentemente true após erro (ACHADO-03)
e sheet que não fecha quando saveAsDraft falha (ACHADO-04)

---

## STATUS — Já aplicado na sessão anterior

> **ACHADO-03 e ACHADO-04 já estão corrigidos e commitados.**
> Commit: `fix(marketing): ACHADO-03/04/05/06 — isLoading reset, sheet close on error, offline-first cache, sheet token`

---

## STEP 0 — Arquivos

```
lib/modules/marketing/presentation/screens/novo_case_sheet.dart
lib/ui/screens/private_map_sheets.dart
```

---

## STEP 3 — Fix ACHADO-03 ✅ APLICADO

`_handlePublicar()` agora envolve `widget.onPublicar(newCase)` em `try/finally`:

```dart
try {
  widget.onPublicar(newCase);
} finally {
  if (mounted) setState(() => _isLoading = false);
}
```

**Verificação:**
- `_isLoading = true` → linha 160
- `_isLoading = false` → linha 270 (dentro do `finally`)
- `flutter analyze` → 0 erros no arquivo

---

## STEP 4 — Fix ACHADO-04 ✅ APLICADO

Bloco `catch` do `saveAsDraft` agora fecha o sheet antes do SnackBar:

```dart
} catch (e) {
  if (!mounted) return;
  Navigator.of(context).pop(); // Fecha sheet mesmo em erro
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro ao salvar rascunho: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## STEP 5 — flutter analyze ✅

```
Analyzing novo_case_sheet.dart → No issues found.
Analyzing private_map_screen.dart → 1 info (withOpacity deprecated, pré-existente, não introduzido por estes fixes)
```

---

## PENDENTES (aprovação individual)

| Achado | Arquivo | Status |
|---|---|---|
| ACHADO-01 | `marketing_photo_service.dart` — rethrow em `StorageException` | ⏳ aguardando aprovação |
| ACHADO-02 | `foto_picker_widget.dart` — `catch (_)` com SnackBar | ⏳ aguardando aprovação |
| ACHADO-05 | `marketing_case_repository_impl.dart` — offline-first real (ADR/DT-028) | ✅ aplicado preventivamente |

---

## REGRAS ABSOLUTAS

❌ Não alterar outros arquivos além dos dois listados
❌ Não refatorar além do objetivo
❌ Não criar providers
❌ Não mover arquivos
✅ Apenas os dois blocos descritos nos STEPS 3 e 4
✅ Sugerir antes de executar se houver ambiguidade
