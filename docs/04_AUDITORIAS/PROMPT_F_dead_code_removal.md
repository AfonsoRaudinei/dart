# PROMPT — Grupo F: Remoção de Dead Code (SmartButton Unificação)

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Arquitetura Clean Architecture
**Tipo:** Remoção Estrutural — Dead Code
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Prioridade 1 Crítica
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulo:** `ui/components` (arquivos isolados sem referências)
**Arquivos tocados (apenas estes dois):**
- `lib/ui/components/private_app_shell.dart` → **DELETAR**
- `lib/ui/components/map/floating_menu_button.dart` → **DELETAR**

🚫 **Proibido alterar:**
- `app_shell.dart`
- `smart_button.dart`
- Qualquer rota, provider, ou módulo
- Qualquer outro arquivo fora dos dois listados acima

---

## 2. OBJETIVO

Deletar dois arquivos de dead code (`PrivateAppShell` e `FloatingMenuButton`) que nunca são instanciados no app e possuem bug crítico de `Positioned` fora de `Stack`.

---

## 3. PRÉ-VALIDAÇÃO OBRIGATÓRIA (antes de deletar)

Execute os seguintes greps e confirme **zero resultados** para cada:

```bash
grep -r "PrivateAppShell" lib/ --include="*.dart"
grep -r "FloatingMenuButton" lib/ --include="*.dart"
grep -r "private_app_shell" lib/ --include="*.dart"
grep -r "floating_menu_button" lib/ --include="*.dart"
```

Se qualquer grep retornar resultado → **INTERROMPER**. Reportar o arquivo que referencia antes de deletar.

---

## 4. EXECUÇÃO

**Somente se todos os greps retornarem zero:**

```bash
rm lib/ui/components/private_app_shell.dart
rm lib/ui/components/map/floating_menu_button.dart
```

---

## 5. VALIDAÇÃO FINAL

```bash
flutter analyze
```

Resultado esperado: **0 errors** (warnings e infos pré-existentes são aceitáveis).

```bash
arch_check.sh
```

Resultado esperado: **Exit 0**

---

## 6. CHECKLIST DE ENCERRAMENTO

- [ ] `private_app_shell.dart` deletado
- [ ] `floating_menu_button.dart` deletado
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0
- [ ] Nenhum outro arquivo foi alterado

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** NÃO
**Contrato alterado?** NÃO
**Apenas os 2 arquivos alvo foram removidos?** SIM

---

## 7. ENCERRAMENTO PADRÃO

O dead code (`PrivateAppShell` + `FloatingMenuButton`) foi removido do SoloForte.
Nenhum outro módulo, rota, estado ou contrato foi alterado.
