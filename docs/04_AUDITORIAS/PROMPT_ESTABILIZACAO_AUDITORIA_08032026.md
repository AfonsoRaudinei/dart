# PROMPT — Sprint de Estabilização Pós-Auditoria (Revisado v2)
**Arquivo:** `prompts/PROMPT_ESTABILIZACAO_AUDITORIA_08032026.md`  
**Data:** 08/03/2026  
**Auditoria base:** `AUDITORIA_COMPLETA_SOLOFORTE` (score 72/100)  
**Tipo:** Refatoração cirúrgica (sem feature nova)  
**Agente:** Engenheiro Sênior Flutter/Dart (Riverpod + Clean Architecture)

---

## 0. Contexto Fixo e Reprodutibilidade

- Projeto: SoloForte App (Flutter/Dart)
- Arquitetura: Map-First + Clean Architecture + Riverpod
- Baseline de referência: `ARCH_BASELINE_v1.1_SCORE_90.md` (commit `0eb0975`)
- Score auditado atual: 72/100
- Objetivo: restaurar gate de qualidade e eliminar os 3 riscos críticos
- `./tool/arch_check.sh` deve permanecer Exit 0 ao final de cada sessão

Antes de iniciar cada sessão, registrar:

```bash
date
git rev-parse --short HEAD
flutter --version
dart --version
```

Regras absolutas:

- Não adicionar features
- Não alterar contrato externo de dados (API, schema remoto, payloads)
- Não criar rotas novas
- Não usar `git add .` ou `git add -A`

Prioridade operacional do sprint:

1. P0: Runtime/estabilidade (lifecycle geofence)
2. P1: Gate de qualidade (testes e analyze sem regressão)
3. P2: Governança/arquitetura (contrato consultoria-visitas)

---

## 1. Escopo do Sprint

Sprint dividido em 3 sessões independentes e sequenciais.  
Não iniciar a próxima sem validação completa da anterior.

---

## SESSÃO 1 — Restaurar gate de qualidade (testes)

### Objetivo

Corrigir os 8 testes com erro e restaurar confiabilidade do pipeline.

### Arquivos-alvo

```bash
find test/ -name "register_golden_test.dart"
find test/ -name "register_widget_test.dart"
find test/ -name "register_flow_test.dart"
find test/ -name "drawing_flow_widget_test.dart"
```

### Passos

1. Capturar baseline da sessão:

```bash
flutter analyze > /tmp/s1_analyze_before.log 2>&1
flutter test --reporter expanded > /tmp/s1_test_before.log 2>&1
grep -E "FAIL|ERROR" /tmp/s1_test_before.log | head -30
```

2. `register_golden_test.dart`:
- remover dependência de tema legado (`soloforte_theme.dart`)
- identificar o tema vigente antes de substituir:

```bash
grep -rn "ThemeData\|AppTheme\|theme" lib/core/ | grep -v ".dart:" | head -20
```

- substituir import pelo tema vigente encontrado
- atualizar golden somente se necessário:

```bash
flutter test --update-goldens
```

3. `register_widget_test.dart` e `register_flow_test.dart`:
- ler o comportamento atual da tela de registro antes de ajustar:

```bash
grep -rn "RegisterScreen\|register_screen" lib/ | head -10
```

- ajustar expectativas para o comportamento atual
- não alterar produção para esses dois casos

4. `drawing_flow_widget_test.dart` (falhas nas linhas 168, 335, 473):
- primeiro tentar ajuste apenas no teste conforme contrato vigente do sheet
- exceção permitida: se for impossível estabilizar sem tocar produção, pode alterar apenas:
  - `lib/modules/drawing/presentation/controllers/drawing_controller.dart`
  - `lib/modules/drawing/presentation/widgets/drawing_sheet.dart`
- se usar exceção: classificar no commit como risco médio de estabilização e descrever o que foi alterado

### Checklist de aceite — Sessão 1

- [ ] 0 erros de teste
- [ ] `arch_check.sh` Exit 0
- [ ] `flutter analyze` sem novos problemas vs baseline capturado antes
- [ ] Nenhum arquivo de produção alterado (exceto se exceção drawing foi acionada)
- [ ] Nenhum import novo entre módulos introduzido

### Commit sugerido

```bash
git add test/auth/register_golden_test.dart
git add test/auth/register_widget_test.dart
git add test/auth/register_flow_test.dart
git add test/modules/drawing/drawing_flow_widget_test.dart
# adicionar arquivos de produção drawing/ somente se exceção foi usada
git commit -m "fix(tests): restaura suite pós-auditoria 08/03/2026"
```

---

## SESSÃO 2 — Fechar lifecycle dos timers no geofence

### Objetivo

Eliminar vazamento de recursos dos timers periódicos de geofence.  
Risco ativo: bateria, estado inválido, comportamento imprevisível no mapa.

### Arquivo-alvo principal

```bash
find lib/ -name "geofence_controller.dart"
```

### Passos

1. Inspeção inicial — não editar ainda:

```bash
cat lib/modules/visitas/presentation/controllers/geofence_controller.dart | head -80
grep -n "Timer\|timer\|onDispose\|autoDispose\|dispose" lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

2. Localizar provider — não assumir pasta fixa:

```bash
grep -rn "geofenceControllerProvider\|GeofenceController" lib/modules/visitas/
```

3. Verificar consumidores antes de alterar:

```bash
grep -rn "geofenceControllerProvider" lib/
```

4. Aplicar correção:
- garantir cancelamento explícito de todos os timers
- centralizar em método privado (`_cancelAllTimers` ou `dispose`)
- usar `ref.onDispose(...)` no provider
- preferir `autoDispose` quando o ciclo de vida depender da tela ou do consumo
- ajustar consumidores somente se a mudança para autoDispose exigir

### Checklist de aceite — Sessão 2

- [ ] 0 timers vivos após descarte do provider (verificável em código)
- [ ] `ref.onDispose` ou `dispose()` explícito e rastreável
- [ ] `arch_check.sh` Exit 0
- [ ] `flutter analyze` sem novos problemas
- [ ] Testes da Sessão 1 continuam verdes

### Commit sugerido

```bash
git add lib/modules/visitas/presentation/controllers/geofence_controller.dart
# adicionar provider relacionado somente se alterado
git commit -m "fix(visitas): fecha lifecycle dos timers do geofence com onDispose"
```

---

## SESSÃO 3 — Extrair contrato entre consultoria e visitas

### Objetivo

Remover acoplamento cruzado entre `consultoria` e `visitas` nas camadas de presentation.  
Padrão a seguir: `IClientLookup` (ADR-015) já existente em `lib/core/contracts/`.

### Atenção antes de começar

O acoplamento **não é necessariamente** entre controllers.  
Pode ser entre controller e provider, entre widgets, ou entre camadas distintas.  
**Mapear primeiro. Decidir depois.**

### Passos

1. Mapear o acoplamento real — não assumir nada:

```bash
grep -rn "import.*visitas" lib/modules/consultoria/
grep -rn "import.*consultoria" lib/modules/visitas/
```

2. Para cada import cruzado encontrado, identificar:
- qual tipo/classe está sendo usado?
- é um modelo, provider, controller ou widget?
- qual é o mínimo necessário para o contrato?

3. Criar interface mínima em `core/contracts/`:

```
lib/core/contracts/i_visit_session_lookup.dart
```

- seguir exatamente o modelo de `lib/core/contracts/i_client_lookup.dart`
- DTO e interface apenas com o necessário — sem expansão

4. Implementar adapter no módulo proprietário (`visitas`) e expor por provider interno.

5. Substituir imports diretos cruzados por imports de `core/contracts/`.

6. Documentação obrigatória:
- criar `docs/02_ARQUITETURA_ATIVA/ADR-019-VISITAS-CONSULTORIA-CONTRACT.md`
- atualizar `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`

7. Validação:

```bash
flutter analyze > /tmp/s3_analyze_after.log 2>&1
flutter test
./tool/arch_check.sh
```

### Checklist de aceite — Sessão 3

- [ ] Nenhum import direto `consultoria <-> visitas` em nenhuma camada
- [ ] Contrato mínimo formalizado em `core/contracts/`
- [ ] ADR-019 criado
- [ ] `bounded_contexts.md` atualizado
- [ ] `arch_check.sh` Exit 0
- [ ] Todos os testes das Sessões 1 e 2 continuam verdes

### Commit sugerido

```bash
git add lib/core/contracts/i_visit_session_lookup.dart
# arquivos de visitas alterados, um por um
git add lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart
git add docs/02_ARQUITETURA_ATIVA/ADR-019-VISITAS-CONSULTORIA-CONTRACT.md
git add docs/02_ARQUITETURA_ATIVA/bounded_contexts.md
git commit -m "refactor(contracts): extrai IVisitSessionLookup e remove acoplamento consultoria-visitas (ADR-019)"
```

---

## 2. Metodologia de Score (Obrigatória na reavaliação pós-sprint)

Na auditoria pós-sprint, usar pesos explícitos:

| Categoria | Peso |
|---|---|
| Enforcement arquitetural | 20% |
| Qualidade de testes | 20% |
| Gestão de estado/lifecycle | 15% |
| Navegação/contratos | 15% |
| Persistência offline | 15% |
| Performance/complexidade | 15% |

```text
score_final = soma(peso_categoria * nota_categoria)
```

Sem pesos explícitos declarados, não publicar score final.

---

## 3. Resultado Esperado

| Métrica | Antes | Depois |
|---|---|---|
| Score estrutural estimado | 72/100 | ~83/100 |
| Testes com erro | 8 | 0 |
| Timers sem dispose | 2 | 0 |
| Acoplamento consultoria-visitas | direto | via contrato |
| Gate de qualidade | quebrado | restaurado |
| ADRs ativos | 018 | 019 |

---

## 4. Gate para Próxima Feature

`GPS Walk / Gravar Rota` só pode iniciar após os 3 checklists estarem 100% verdes.  
Depende diretamente do geofence estabilizado (Sessão 2).

---

*Prompt: Claude Sonnet 4.6 — 08/03/2026 — v2*  
*Base: AUDITORIA_COMPLETA_SOLOFORTE + ARCH_BASELINE_v1.1_SCORE_90*  
*Execução: Antigravity / GitHub Copilot*