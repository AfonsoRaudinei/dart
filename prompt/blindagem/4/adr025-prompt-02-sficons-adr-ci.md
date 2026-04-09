# ADR-025 PROMPT 02 — `sf_icons.dart` + ADR-025 + REGRA-MAP-1
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Alteração Estrutural
**Arquivos alvo:**
  - `lib/modules/map/design/sf_icons.dart` (MOVER para `lib/core/design/`)
  - `docs/02_ARQUITETURA_ATIVA/ADR-025-MODULO-MAP.md` (CRIAR)
  - `tool/arch_check.sh` (ADICIONAR REGRA-MAP-1)
  - Todos os importadores de `sf_icons.dart` (ATUALIZAR import path)
**Tipo:** ALTERAÇÃO ESTRUTURAL — mover arquivo + documentação + CI
**Pré-requisito:** PROMPT 01 executado — relatório disponível
**Risco:** Médio — move arquivo com 14+ importadores; atualizar todos

---

## OBJETIVO

Mover `sf_icons.dart` para zona neutra (`lib/core/design/`),
eliminar o acoplamento artificial `consultoria/ → map/`,
criar ADR-025 com bounded context formal de `map/`,
e adicionar REGRA-MAP-1 ao CI proibindo imports externos de `map/`.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar o conteúdo de `sf_icons.dart` — apenas mover
❌ Não alterar lógica de nenhum arquivo que importa `sf_icons.dart`
❌ Não mover `lib/ui/components/map/` (Fase 3 — ADR futuro)
❌ Não alterar `visit_completion_observer.dart` (PROMPT 03)
❌ Não criar imports novos além da atualização de path

---

## PASSO 0 — VERIFICAÇÃO

```bash
# Localizar sf_icons.dart
find lib/ -name "sf_icons.dart" | sort

# Listar todos os importadores
grep -rn "import.*sf_icons\|import.*map/design/sf_icons" \
  lib/ --include="*.dart" | sort

# Verificar se lib/core/design/ existe
find lib/core/design/ -type f 2>/dev/null | sort || echo "AUSENTE"

# Confirmar conteúdo do arquivo
cat lib/modules/map/design/sf_icons.dart
```

Confirmar:
1. `sf_icons.dart` existe no path esperado
2. Listar TODOS os importadores — nenhum pode ser esquecido
3. `lib/core/design/` existe ou precisa ser criada

---

## PASSO 1 — MOVER `sf_icons.dart`

```bash
# Se lib/core/design/ não existir, criar o diretório
mkdir -p lib/core/design/

# Copiar para o destino (não deletar ainda)
cp lib/modules/map/design/sf_icons.dart lib/core/design/sf_icons.dart
```

Verificar que o arquivo foi copiado corretamente:
```bash
diff lib/modules/map/design/sf_icons.dart lib/core/design/sf_icons.dart
```

Resultado esperado: **zero diferenças**.

---

## PASSO 2 — ATUALIZAR TODOS OS IMPORTADORES

Para cada arquivo que importa `sf_icons.dart`:

```bash
# Listar com path completo
grep -rln "import.*sf_icons\|import.*map/design/sf_icons" \
  lib/ --include="*.dart"
```

Substituir o import antigo pelo novo em cada arquivo:

```dart
// ANTES (variações possíveis):
import 'package:soloforte_app/modules/map/design/sf_icons.dart';
// ou
import '../../../modules/map/design/sf_icons.dart';

// DEPOIS:
import 'package:soloforte_app/core/design/sf_icons.dart';
```

Usar `sed` para fazer a substituição em massa, mas verificar cada arquivo depois:

```bash
# Substituição em massa
grep -rln "modules/map/design/sf_icons" lib/ --include="*.dart" | \
  xargs sed -i '' \
  's|modules/map/design/sf_icons|core/design/sf_icons|g'

# Verificar que não sobrou nenhum import antigo
grep -rn "modules/map/design/sf_icons\|map/design/sf_icons" \
  lib/ --include="*.dart"
```

Resultado esperado: **zero resultados**.

---

## PASSO 3 — DELETAR ARQUIVO ORIGINAL

Somente após confirmar zero importadores do path antigo:

```bash
# Confirmar zero importadores do path antigo
grep -rn "modules/map/design/sf_icons" lib/ --include="*.dart"
# Se vazio → deletar
rm lib/modules/map/design/sf_icons.dart

# Se lib/modules/map/design/ ficou vazia → remover pasta
rmdir lib/modules/map/design/ 2>/dev/null || true
```

---

## PASSO 4 — VERIFICAR COMPILAÇÃO

```bash
flutter analyze lib/modules/consultoria/ 2>&1 | grep -E "^.*error"
flutter analyze lib/modules/settings/ 2>&1 | grep -E "^.*error"
flutter analyze lib/ui/ 2>&1 | grep -E "^.*error"
flutter analyze lib/core/ 2>&1 | grep -E "^.*error"
```

Zero erros novos em todos.

---

## PASSO 5 — CRIAR ADR-025

Criar `docs/02_ARQUITETURA_ATIVA/ADR-025-MODULO-MAP.md`:

```markdown
# ADR-025 — Módulo `map/` — Bounded Context Formal

**Data:** <hoje>
**Branch:** release/v1.1
**Status:** APROVADO — com dívidas técnicas registradas
**Tipo:** FORMALIZAÇÃO + CORREÇÃO DE ANOMALIA ESTRUTURAL
**Altera fronteira entre módulos?** SIM — move sf_icons para core/design/
**arch_check.sh:** REGRA-MAP-1 adicionada

---

## 1. Contexto

O módulo `map/` é o agregador central do SoloForte. Por design, pode
depender de todos os outros módulos. O problema identificado na auditoria:
o módulo `map/` está fragmentado em 3 locais no disco, sem ADR formal
e sem regra CI declarando que ninguém pode importar `map/`.

---

## 2. Responsabilidade do Módulo

**Natureza:** Projeção agregadora — orquestração visual do mapa
**Bounded context:** `map/` + `lib/ui/components/map/` + `lib/ui/screens/`
**Regra fundamental:** Pode depender de tudo. Ninguém depende dele.

---

## 3. Fragmentação Atual (aceita como dívida)

| Local | Conteúdo | Status |
|---|---|---|
| `lib/modules/map/` | 7 arquivos — domínio, providers, 1 widget | Formal |
| `lib/ui/components/map/` | ~20 arquivos — widgets, sheets, overlays | Informal |
| `lib/ui/screens/` | `private_map_screen.dart` + `private_map_sheets.dart` | Informal |
| `lib/core/state/` | `map_ui_providers.dart` | Mislocado |

Consolidação em `lib/modules/map/presentation/` é dívida técnica
registrada como DT-025-4 (Fase 3 — ADR futuro).

---

## 4. Fronteiras Declaradas

| Direção | Status |
|---|---|
| `map/` → `agenda/` | ✅ PERMITIDO |
| `map/` → `operacao/` | ✅ PERMITIDO |
| `map/` → `drawing/` | ✅ PERMITIDO |
| `map/` → `consultoria/` | ✅ PERMITIDO |
| `map/` → `visitas/` via contratos | ✅ PERMITIDO |
| `map/` → `visitas/` direto | ⚠️ A MIGRAR — DT-025-3 |
| `map/` → `planos/` | ✅ PERMITIDO (badge SideMenu) |
| `map/` → `marketing/` | ✅ PERMITIDO (markers) |
| qualquer módulo → `map/` | ❌ PROIBIDO (REGRA-MAP-1) |
| `main.dart` → `visit_completion_observer` bootstrap | ✅ EXCEÇÃO AUTORIZADA |

---

## 5. Dívidas Técnicas Registradas

| # | Item | Risco | Ação |
|---|---|---|---|
| DT-025-1 | `sf_icons.dart` em namespace errado | Alto | ✅ RESOLVIDO — PROMPT 02 |
| DT-025-2 | `visit_completion_observer` com 7 imports concretos | Alto | PROMPT 03 |
| DT-025-3 | `lib/ui/` importa `visitas/` direto (DT-023-5) | Médio | ADR-025 Fase 2+ |
| DT-025-4 | Fragmentação em 3 locais do disco | Médio | ADR futuro (Fase 3) |
| DT-025-5 | `private_map_screen.dart` com 898 linhas (limite: 900) | Alto | Governance imediata |
| DT-025-6 | `map_occurrence_sheet.dart` com 1089 linhas (legado) | Médio | Monitorado |
| DT-025-7 | `map_ui_providers.dart` em `core/state/` (mislocado) | Baixo | ADR futuro |
| DT-025-8 | Proxy ADR-010 em `visit_completion_observer` | Baixo | Junto com DT-025-2 |

---

## 6. Governance de `private_map_screen.dart`

Arquivo em 898 linhas — 2 abaixo do limite.
**Regra imediata:** qualquer adição de funcionalidade DEVE ser
implementada em widget separado e apenas referenciada em
`private_map_screen.dart`. Nunca adicionar código inline neste arquivo.

---

## 7. O que NÃO muda neste ADR

- Fragmentação de `lib/ui/components/map/` — registrada, não movida
- Lógica de nenhum controller ou provider
- Contratos existentes de outros módulos
```

---

## PASSO 6 — ADICIONAR REGRA-MAP-1 AO `arch_check.sh`

### 6a — Simular antes de adicionar

```bash
# Verificar que após mover sf_icons a regra não vai disparar falso positivo
grep -rn "import.*modules/map" lib/ --include="*.dart" \
  | grep -v "lib/modules/map/" \
  | grep -v "lib/core/router/app_router" \
  | grep -v "lib/main.dart" \
  | grep -v "lib/ui/components/map/" \
  | grep -v "lib/ui/screens/"
```

Resultado esperado: **vazio** após a remoção de `sf_icons.dart`.
Se não estiver vazio → identificar e resolver antes de adicionar a regra.

### 6b — Adicionar ao `arch_check.sh`

```bash
# ─────────────────────────────────────────────────────────────
# REGRA-MAP-1 — ninguém importa modules/map/ (ADR-025)
# map/ é agregador — dependências entram, não saem
# EXCEÇÕES AUTORIZADAS:
#   - lib/core/router/app_router.dart (composição de rotas)
#   - lib/main.dart (bootstrap visit_completion_observer — ADR-010)
#   - lib/ui/components/map/ (camada de apresentação do mapa — DT-025-4)
#   - lib/ui/screens/ (camada de apresentação do mapa — DT-025-4)
# ─────────────────────────────────────────────────────────────
MAP_IMPORTS_EXTERNOS=$(grep -rn "import.*modules/map" lib/ \
  --include="*.dart" \
  | grep -v "lib/modules/map/" \
  | grep -v "lib/core/router/app_router" \
  | grep -v "lib/main\.dart" \
  | grep -v "lib/ui/components/map/" \
  | grep -v "lib/ui/screens/" \
  | grep -v "^\s*//" \
  | wc -l | tr -d ' ')

if [ "$MAP_IMPORTS_EXTERNOS" -gt "0" ]; then
  echo "❌ REGRA-MAP-1 VIOLADA: módulo externo importa map/ diretamente"
  grep -rn "import.*modules/map" lib/ --include="*.dart" \
    | grep -v "lib/modules/map/" \
    | grep -v "lib/core/router/app_router" \
    | grep -v "lib/main\.dart" \
    | grep -v "lib/ui/components/map/" \
    | grep -v "lib/ui/screens/" \
    | grep -v "^\s*//"
  EXIT_CODE=1
fi
```

---

## PASSO 7 — ARCH_CHECK COMPLETO

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0** com REGRA-MAP-1 ativa.

---

## PASSO 8 — ATUALIZAR `bounded_contexts.md` E `00_INDEX_OFICIAL.md`

Em `bounded_contexts.md`, atualizar a seção `map`:
- Adicionar regra formal: "Ninguém depende de `map/`"
- Referenciar ADR-025
- Listar dívidas DT-025-N

Em `00_INDEX_OFICIAL.md`:
- Adicionar ADR-025 na lista de ADRs ativos

---

## VALIDAÇÃO FINAL

- [ ] `sf_icons.dart` em `lib/core/design/`?
- [ ] Nenhum arquivo importa `modules/map/design/sf_icons` ?
- [ ] `lib/modules/map/design/` deletada?
- [ ] `flutter analyze` sem erros novos em todos os módulos?
- [ ] ADR-025 criado com 8 dívidas rastreadas?
- [ ] REGRA-MAP-1 no `arch_check.sh` com exceções corretas?
- [ ] `arch_check.sh` Exit 0?
- [ ] `bounded_contexts.md` atualizado?

---

## MENSAGEM DE COMMIT

```
feat(map,adr025): bounded context formal + move sf_icons + REGRA-MAP-1

- Move sf_icons.dart: modules/map/design/ → core/design/
  (remove acoplamento artificial consultoria/ → map/ em 14+ arquivos)
- Cria ADR-025-MODULO-MAP.md com 8 dívidas rastreadas
- Adiciona REGRA-MAP-1 ao arch_check.sh
- Atualiza bounded_contexts.md e 00_INDEX_OFICIAL.md
- arch_check.sh: Exit 0
- flutter analyze: 0 erros novos

DT-025-1: ✅ resolvida neste commit
DT-025-2/3/4/5/6/7/8: registradas — ver ADR-025
```

---

## ENCERRAMENTO

`sf_icons.dart` fora do namespace errado.
REGRA-MAP-1 ativa no CI.
ADR-025 documenta o bounded context com dívidas rastreadas.
Próximo: PROMPT 03 — migrar `visit_completion_observer.dart`
para contratos ADR-024 (DT-025-2).
