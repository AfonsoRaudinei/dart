# PROMPT — Limpeza de Plataformas Não-Mobile (SoloForte)

**Agente:** Engenheiro Sênior Flutter/Dart — Operação de Limpeza Estrutural  
**Risco:** Médio (operação destrutiva e irreversível no repositório)  
**Arquivo-alvo:** raiz do projeto `APPDART/`  
**Módulo afetado:** nenhum módulo de `lib/` — apenas scaffolding de plataforma  

---

## ⚠️ PRÉ-REQUISITO OBRIGATÓRIO — EXECUTAR ANTES DE QUALQUER COISA

Antes de deletar qualquer arquivo ou pasta, o agente **DEVE** confirmar:

```bash
# 1. Verificar que não há nada staged ou modified importante
git status

# 2. Verificar branch atual — NUNCA executar em main ou release/*
git branch --show-current

# 3. Criar branch de segurança exclusiva para esta operação
git checkout -b chore/remove-non-mobile-platforms

# 4. Confirmar que arch_check.sh passa ANTES da limpeza (baseline limpa)
chmod +x tool/arch_check.sh && ./tool/arch_check.sh
```

**Se arch_check retornar Exit 1 → PARAR. Não continuar.**

---

## OBJETIVO

Remover as pastas de plataforma não-mobile (`web/`, `linux/`, `windows/`) e os arquivos de rascunho/debug soltos na raiz do projeto, e fazer commit documentado por etapa.

---

## ESCOPO

**Pastas a remover:**
```
web/
linux/
windows/
```

**Arquivos soltos na raiz a remover** (verificar existência antes de deletar):
```
test_debug.dart
test_debug2.dart
test_part.dart
update_side_menu.dart
run_update.sh
flutter_01.log
drawing_tests.log
```

**⚠️ NÃO TOCAR:**
```
macos/        ← manter (simulador iOS usa entorno macOS; risco real)
android/      ← manter (plataforma-alvo principal)
ios/          ← manter (plataforma-alvo principal)
lib/          ← intocável
test/         ← intocável
prompt/       ← intocável
tool/         ← intocável
docs/         ← intocável
assets/       ← intocável
pubspec.yaml  ← intocável
pubspec.lock  ← intocável
```

---

## EXECUÇÃO — PASSO A PASSO

### Etapa 1 — Remover pasta `web/`

```bash
# Confirmar existência
ls -la web/

# Remover
rm -rf web/

# Verificar que lib/ continua intacto
ls lib/ | head -5

# Commit individual
git add -u
git commit -m "chore: remove web platform scaffold (mobile-only project)"
```

### Etapa 2 — Remover pasta `linux/`

```bash
rm -rf linux/
git add -u
git commit -m "chore: remove linux platform scaffold (mobile-only project)"
```

### Etapa 3 — Remover pasta `windows/`

```bash
rm -rf windows/
git add -u
git commit -m "chore: remove windows platform scaffold (mobile-only project)"
```

### Etapa 4 — Remover arquivos de rascunho da raiz

```bash
# Remover APENAS os arquivos listados que existirem
# Verificar existência de cada um antes de deletar:

[ -f test_debug.dart ]  && rm test_debug.dart
[ -f test_debug2.dart ] && rm test_debug2.dart
[ -f test_part.dart ]   && rm test_part.dart
[ -f update_side_menu.dart ] && rm update_side_menu.dart
[ -f run_update.sh ]    && rm run_update.sh
[ -f flutter_01.log ]   && rm flutter_01.log
[ -f drawing_tests.log ] && rm drawing_tests.log

# Verificar o que foi removido
git status

# Commit
git add -u
git commit -m "chore: remove debug/rascunho files from project root"
```

### Etapa 5 — Validação final

```bash
# arch_check deve continuar Exit 0
./tool/arch_check.sh

# flutter analyze deve manter 0 erros, 1 warning pré-existente
flutter analyze

# 67 testes devem continuar verdes
flutter test test/
```

**Se qualquer validação falhar → rollback imediato:**
```bash
git checkout main
git branch -D chore/remove-non-mobile-platforms
```

### Etapa 6 — Merge (só após validação 100% verde)

```bash
git checkout main
git merge chore/remove-non-mobile-platforms --no-ff \
  -m "chore: remove non-mobile platform scaffolds and debug files"
```

---

## VALIDAÇÃO FINAL

| Verificação | Esperado |
|---|---|
| arch_check.sh | Exit 0 |
| flutter analyze | 0 erros, 1 warning pré-existente |
| flutter test | 67/67 verdes |
| `lib/` intacto | SIM |
| `android/` intacto | SIM |
| `ios/` intacto | SIM |
| `macos/` intacto | SIM |
| Módulos alterados | NENHUM |
| Contratos alterados | NENHUM |

---

## ENCERRAMENTO

As pastas de plataforma não-mobile e arquivos de rascunho foram removidos.  
Nenhum módulo, contrato, rota, provider ou estado do SoloForte foi alterado.
