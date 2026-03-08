# PROMPT — Grupo E: Correção SafeArea Dinâmica no AppShell

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Layout e SafeArea
**Tipo:** Bugfix — Posicionamento Frágil
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erro 7 — Prioridade 1 Crítica
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulo:** `ui/components`
**Arquivo tocado (único):**
- `lib/ui/components/app_shell.dart`

🚫 **Proibido alterar:**
- `smart_button.dart`
- `layout_constants.dart`
- Qualquer módulo, rota, provider ou outro arquivo

---

## 2. OBJETIVO

Substituir o valor fixo `bottom: 40` no `Positioned` do SmartButton dentro do `AppShell` por cálculo dinâmico baseado em `MediaQuery.of(context).padding.bottom + 16`, eliminando colisão com a barra de sistema em iPhones e dispositivos com gesture bar.

---

## 3. CONTRATO DE DADOS

**Não há alteração de entidade ou provider.**
**Mudança é puramente de layout.**

---

## 4. LOCALIZAÇÃO EXATA DO CÓDIGO A ALTERAR

```dart
// ANTES — app_shell.dart (linha aproximada)
Positioned(
  bottom: 40,   // ← fixo, sem respeitar SafeArea
  right: 20,
  child: _SmartButtonWrapper(),
),
```

```dart
// DEPOIS
Positioned(
  bottom: MediaQuery.of(context).padding.bottom + 16,
  right: 16,
  child: _SmartButtonWrapper(),
),
```

**Notas:**
- `right: 20` → `right: 16` (alinhamento com padrão de 16dp do Material)
- `bottom: 40` → `MediaQuery.of(context).padding.bottom + 16`
- Não usar `SafeArea` como wrapper pois o `Positioned` já está dentro de `Stack` que cobre a tela inteira

---

## 5. PERFORMANCE

- Zero widget rebuild adicional (MediaQuery já estava sendo lido no contexto do Scaffold)
- Sem impacto no mapa

---

## 6. VALIDAÇÃO FINAL

```bash
flutter analyze
```
Resultado esperado: **0 errors**

```bash
arch_check.sh
```
Resultado esperado: **Exit 0**

**Teste manual:**
- Abrir app em iPhone com barra home (SafeArea bottom > 0)
- Confirmar SmartButton visível acima da barra de gesture
- Abrir app em Android sem gesture bar
- Confirmar SmartButton em posição correta

---

## 7. CHECKLIST DE ENCERRAMENTO

- [ ] `bottom: 40` substituído por `MediaQuery.of(context).padding.bottom + 16`
- [ ] `right: 20` ajustado para `right: 16`
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0
- [ ] Nenhum outro arquivo foi alterado

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** NÃO
**Contrato alterado?** NÃO
**Apenas `app_shell.dart` foi alterado?** SIM

---

## 8. ENCERRAMENTO PADRÃO

O `AppShell` foi corrigido para usar SafeArea dinâmica no SmartButton.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
