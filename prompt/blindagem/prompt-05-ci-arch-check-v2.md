# PROMPT 05 — CI: Fechar ponto cego do `arch_check.sh` para `visitas/`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo DevOps/CI
**Arquivo alvo:** `tool/arch_check.sh`
**Tipo:** ALTERAÇÃO DE ENFORCEMENT — adicionar regras ao CI
**Pré-requisito:** PROMPT 04 executado — violações corrigidas
**Risco:** Médio — alteração do CI; uma regra mal escrita bloqueia todos os PRs

---

## OBJETIVO

Adicionar regras ao `arch_check.sh` que detectem imports proibidos
na camada de **dados e controllers** de `visitas/`, fechando o ponto
cego documentado em ADR-023 seção 7 (DT-023-6).

---

## PROIBIÇÕES ABSOLUTAS

❌ Não remover regras existentes do `arch_check.sh`
❌ Não alterar regras de outros módulos
❌ Não adicionar regra que detecte imports autorizados como violação
❌ Não alterar arquivos `.dart`
❌ Testar SEMPRE antes de commitar — uma regra errada bloqueia CI

---

## PASSO 0 — LER O ARQUIVO ATUAL COMPLETO

```bash
cat tool/arch_check.sh
```

Ler o arquivo inteiro antes de qualquer edição.
Identificar:
1. Onde ficam as regras de REGRA 2 (acoplamento lateral)
2. O padrão exato de cada verificação (formato do grep)
3. O padrão de saída (echo + exit 1)

---

## PASSO 1 — SIMULAR AS NOVAS REGRAS ANTES DE ADICIONAR

Antes de editar o arquivo, simular cada grep manualmente para garantir
que retorna zero resultados (PROMPT 04 já resolveu as violações):

```bash
# Simular REGRA-VISITAS-1: visitas/ não deve importar consultoria/
echo "--- Simulando REGRA-VISITAS-1 ---"
grep -rn "import.*modules/consultoria" lib/modules/visitas/ --include="*.dart"
echo "Resultado acima deve estar VAZIO para a regra ser segura"

# Simular REGRA-VISITAS-2: visitas/ não deve importar drawing/
echo "--- Simulando REGRA-VISITAS-2 ---"
grep -rn "import.*modules/drawing" lib/modules/visitas/ --include="*.dart"
echo "Resultado acima deve estar VAZIO"

# Simular REGRA-VISITAS-3: visitas/ não deve importar providers de agenda/ diretamente
echo "--- Simulando REGRA-VISITAS-3 ---"
grep -rn "import.*modules/agenda.*presentation" lib/modules/visitas/ --include="*.dart"
echo "Resultado acima deve estar VAZIO"
```

⚠️ Se qualquer simulação retornar resultado → o PROMPT 04 não foi concluído.
PARAR. Não adicionar as regras. Resolver PROMPT 04 primeiro.

---

## PASSO 2 — ADICIONAR AS NOVAS REGRAS AO `arch_check.sh`

Após confirmar que todas as simulações retornam vazio, adicionar
o bloco abaixo no `arch_check.sh` na seção de REGRA 2
(após as regras existentes de `drawing → consultoria`, `agenda → consultoria`):

```bash
# ─────────────────────────────────────────────────────────────
# REGRA-VISITAS-1 — visitas/ não importa consultoria/ (ADR-023)
# Cobre camada de dados E presentation (ponto cego anterior)
# ─────────────────────────────────────────────────────────────
VISITAS_IMPORTS_CONSULTORIA=$(grep -rn "import.*modules/consultoria" \
  lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//" | wc -l | tr -d ' ')

if [ "$VISITAS_IMPORTS_CONSULTORIA" -gt "0" ]; then
  echo "❌ REGRA-VISITAS-1 VIOLADA: visitas/ importa consultoria/ diretamente"
  echo "   Arquivos com violação:"
  grep -rn "import.*modules/consultoria" lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//"
  EXIT_CODE=1
fi

# ─────────────────────────────────────────────────────────────
# REGRA-VISITAS-2 — visitas/ não importa drawing/ (ADR-023)
# ─────────────────────────────────────────────────────────────
VISITAS_IMPORTS_DRAWING=$(grep -rn "import.*modules/drawing" \
  lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//" | wc -l | tr -d ' ')

if [ "$VISITAS_IMPORTS_DRAWING" -gt "0" ]; then
  echo "❌ REGRA-VISITAS-2 VIOLADA: visitas/ importa drawing/ diretamente"
  grep -rn "import.*modules/drawing" lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//"
  EXIT_CODE=1
fi

# ─────────────────────────────────────────────────────────────
# REGRA-VISITAS-3 — visitas/ não importa presentation layer de agenda/ (ADR-023)
# Acesso a agenda/ deve ser via core/contracts/ apenas
# ─────────────────────────────────────────────────────────────
VISITAS_IMPORTS_AGENDA_PRESENTATION=$(grep -rn "import.*modules/agenda.*presentation" \
  lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//" | wc -l | tr -d ' ')

if [ "$VISITAS_IMPORTS_AGENDA_PRESENTATION" -gt "0" ]; then
  echo "❌ REGRA-VISITAS-3 VIOLADA: visitas/ importa presentation de agenda/ diretamente"
  grep -rn "import.*modules/agenda.*presentation" lib/modules/visitas/ --include="*.dart" | grep -v "^\s*//"
  EXIT_CODE=1
fi
```

**Regra de inserção:** adicionar o bloco ANTES do `exit $EXIT_CODE` final do script.
Não adicionar após o exit.

---

## PASSO 3 — VERIFICAR QUE O BLOCO FOI INSERIDO CORRETAMENTE

```bash
grep -n "REGRA-VISITAS" tool/arch_check.sh
```

Deve retornar 3 linhas (uma por regra).

---

## PASSO 4 — EXECUTAR ARCH_CHECK COMPLETO

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado:
- **Exit 0**
- As novas regras `REGRA-VISITAS-1/2/3` não produziram saída de erro
- As regras anteriores continuam sem saída de erro

Se Exit 1 → ler qual regra disparou → PARAR e investigar antes de commitar.

---

## PASSO 5 — TESTAR QUE AS REGRAS DETECTAM VIOLAÇÕES (teste negativo)

Criar um arquivo temporário de teste para validar que as regras funcionam:

```bash
# Criar arquivo com import proibido temporariamente
cat > /tmp/test_violation.dart << 'EOF'
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
EOF

# Simular como se estivesse em visitas/
cp /tmp/test_violation.dart lib/modules/visitas/test_violation_temp.dart

# Rodar arch_check — deve detectar a violação
bash tool/arch_check.sh 2>&1 | grep "REGRA-VISITAS-1"

# Remover arquivo temporário IMEDIATAMENTE
rm lib/modules/visitas/test_violation_temp.dart

echo "Se a linha acima mostrou REGRA-VISITAS-1 VIOLADA, a regra funciona ✅"
```

---

## PASSO 6 — ATUALIZAR `enforcement-rules.md`

Adicionar as 3 novas regras na tabela de regras:

```markdown
| REGRA-VISITAS-1 | CRÍTICA | `visitas/ → consultoria/` proibido — PR bloqueado |
| REGRA-VISITAS-2 | CRÍTICA | `visitas/ → drawing/` proibido — PR bloqueado |
| REGRA-VISITAS-3 | CRÍTICA | `visitas/ → agenda/presentation/` proibido — PR bloqueado |
```

---

## PASSO 7 — ATUALIZAR ADR-023

```markdown
DT-023-6: arch_check.sh sem cobertura da camada de dados → ✅ RESOLVIDO — PROMPT 05
  Regras adicionadas: REGRA-VISITAS-1, REGRA-VISITAS-2, REGRA-VISITAS-3
```

---

## VALIDAÇÃO FINAL

- [ ] 3 novas regras adicionadas ao `arch_check.sh`?
- [ ] Regras anteriores intactas (não modificadas)?
- [ ] `arch_check.sh` Exit 0 com novas regras?
- [ ] Teste negativo confirmou que regras detectam violações?
- [ ] `enforcement-rules.md` atualizado?
- [ ] ADR-023 DT-023-6 marcada como resolvida?
- [ ] Nenhum arquivo `.dart` foi tocado?

---

## ENCERRAMENTO

O CI agora detecta automaticamente qualquer tentativa de reintroduzir
os acoplamentos proibidos em `visitas/`.
O PROMPT 06 faz a auditoria final de todo o ciclo antes do commit.
