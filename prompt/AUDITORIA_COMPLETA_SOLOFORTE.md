# PROMPT DE AUDITORIA COMPLETA — SOLOFORTE
> Agente: Engenheiro Sênior Flutter/Dart — Especialista em Auditoria e Performance
> Modo: READ-ONLY até STEP 9. Nenhum arquivo alterado neste prompt.
> Objetivo: Mapear bugs, duplicações, problemas de UI/UX, performance e dívidas técnicas reais.
> Saída esperada: Relatório estruturado com checklist preenchido + lista de findings priorizados.

---

## STEP 0 — LOCALIZAÇÃO DE ARQUIVOS CRÍTICOS

Execute cada find antes de qualquer leitura:

```bash
# Tela principal
find lib/ -name "private_map_screen.dart"
find lib/ -name "private_map_sheets.dart"
find lib/ -name "app_shell.dart"
find lib/ -name "smart_button.dart"

# Módulo agenda duplicado
find lib/ -path "*/agenda*" -name "*.dart" | sort

# Módulo relatorios (3 versões suspeitas)
find lib/ -path "*/relatorio*" -name "*.dart" | sort
find lib/ -path "*/relatorios*" -name "*.dart" | sort
find lib/ -path "*/relatorio_visita*" -name "*.dart" | sort
find lib/ -path "*/reports*" -name "*.dart" | sort

# Providers gerados (.g.dart)
find lib/ -name "*.g.dart" | sort

# Arquivos suspeitos de duplicação
find lib/ -name "*.dart" | xargs -I{} basename {} | sort | uniq -d

# Arquivos maiores que 500 linhas (candidatos a God Object)
find lib/ -name "*.dart" -exec wc -l {} + | sort -rn | head -30

# Todos os controllers
find lib/ -name "*controller*" -o -name "*Controller*" | grep "\.dart$" | sort

# Todos os providers
find lib/ -name "*provider*" -o -name "*Provider*" | grep "\.dart$" | sort

# Arquivos com TODO/FIXME/HACK
grep -rn "TODO\|FIXME\|HACK\|XXX\|TEMP\|hack\|workaround" lib/ --include="*.dart"

# print() em produção (proibido)
grep -rn "^\s*print(" lib/ --include="*.dart"

# debugPrint fora de debug mode
grep -rn "debugPrint(" lib/ --include="*.dart" | grep -v "_test.dart"
```

---

## STEP 1 — AUDITORIA DE DUPLICAÇÕES

### 1.1 Módulo Agenda (risco MÉDIO documentado)

Leia os dois módulos e responda:

```bash
# Módulo principal
cat lib/modules/agenda/presentation/controllers/*.dart

# Sub-módulo legado
cat lib/modules/consultoria/agenda/presentation/controllers/agenda_controller.dart
```

**Checklist agenda:**
- [ ] `lib/modules/agenda/` e `lib/modules/consultoria/agenda/` possuem lógica idêntica ou similar?
- [ ] Qual módulo é efetivamente usado nas rotas ativas?
- [ ] O módulo não usado tem dependências que o impedem de remoção direta?
- [ ] Existe import cruzado entre os dois?
- [ ] Registrar: qual deve ser KEEPER e qual deve ser TARGET de remoção futura?

### 1.2 Módulo Relatórios (3 versões — risco MÉDIO documentado)

```bash
# Versão 1: relatorios/ (ADR-013)
find lib/modules/consultoria/relatorios/ -name "*.dart" | sort

# Versão 2: relatorio_visita/ (sem ADR)
find lib/modules/consultoria/relatorio_visita/ -name "*.dart" | sort

# Versão 3: reports/ (sem ADR)
find lib/modules/consultoria/reports/ -name "*.dart" | sort
```

**Checklist relatórios:**
- [ ] As 3 versões têm entidades/modelos com campos sobrepostos?
- [ ] Existem telas duplicadas resolvendo o mesmo problema de UI?
- [ ] As 3 versões são realmente domínios distintos (relato visita / tipado PDF / publicação)?
- [ ] Alguma versão está sem uso efetivo nas rotas?
- [ ] `relatorio_visita/visita_model.dart` e `relatorios/` têm campos redundantes?

### 1.3 Providers duplicados (.g.dart)

```bash
# Identificar providers com responsabilidade similar
grep -rn "Provider\|Notifier\|StateProvider" lib/ --include="*.dart" \
  | grep -v ".g.dart" | grep -v "_test.dart" \
  | awk -F: '{print $1}' | sort -u
```

**Checklist providers:**
- [ ] Existem dois providers para o mesmo dado (ex: dois locationProviders)?
- [ ] Algum provider está declarado mas nunca consumido com `ref.watch` ou `ref.read`?
- [ ] Providers com `autoDispose` ausente onde deveria existir (telas não-persistentes)?
- [ ] `public_publications_provider.g.dart` aparece duplicado no baseline — confirmar?

---

## STEP 2 — AUDITORIA DE UI E FLUIDEZ

### 2.1 Tela principal — private_map_screen.dart

```bash
wc -l lib/ui/screens/private_map_screen.dart
cat lib/ui/screens/private_map_screen.dart
```

**Checklist private_map_screen:**
- [ ] Arquivo ultrapassa 900 linhas? (limite de governança)
- [ ] Existe algum `setState` na tela principal? (deveria ser zero — tudo via Riverpod)
- [ ] Há `build()` chamando lógica pesada síncrona (ex: loops, cálculos, leitura de DB)?
- [ ] Há widgets não-`const` que poderiam ser `const`?
- [ ] O mapa recebe `rebuild` desnecessário quando estado não relacionado muda?
- [ ] Existe `initState` com side effects que poderiam ser `ref.listen`?
- [ ] A coluna de 5 botões (edit/layers/ocorrências/marketing/check-in) está usando `const` onde possível?
- [ ] O tile provider Stadia Stamen Terrain está corretamente configurado sem fallback OSM?
- [ ] O tile Google Satellite (`lyrs=y`) está encapsulado separadamente sem vazar para o tile padrão?

### 2.2 Overlay e Sheets — private_map_sheets.dart

```bash
cat lib/ui/screens/private_map_sheets.dart
```

**Checklist sheets:**
- [ ] Sheets usam `showModalBottomSheet` puro ou o novo `OccurrenceCreationSheet` (ADR-027)?
- [ ] Algum sheet ainda usa `MapOccurrenceSheet` (deprecated)?
- [ ] Sheets têm `isScrollControlled: true` quando o conteúdo ultrapassa 50% da tela?
- [ ] Existe `DraggableScrollableSheet` sem `initialChildSize` definido explicitamente?
- [ ] Sheets têm padding de `MediaQuery.of(context).viewInsets.bottom` para teclado?
- [ ] ADR-027 F2 (Grupo A — 11 arquivos) e F3 (Grupo B — 7 arquivos) estão pendentes — listar quais sheets ainda não foram migradas.

### 2.3 app_shell.dart — SmartButton e FAB único

```bash
cat lib/ui/components/app_shell.dart
```

**Checklist app_shell:**
- [ ] `_isInitializing` é zerado corretamente no primeiro `onAuthStateChange`?
- [ ] O comentário documentado na linha 13 está presente?
- [ ] Existe `_authSubscription` com `.cancel()` no `dispose()`?
- [ ] O `SmartButton` FAB é realmente único (nenhum módulo declara FAB próprio)?
- [ ] O bootstrap não causa tela preta em cold start (SessionUnknown → Authenticated)?

### 2.4 SideMenu — side_menu_overlay.dart

```bash
find lib/ -name "side_menu_overlay.dart"
cat lib/ui/... # (caminho encontrado no find)
```

**Checklist SideMenu:**
- [ ] Clima e Calculadora estão com `Opacity(opacity: 0.45)` (stubs visuais)?
- [ ] Nenhum item stub está com `onTap` funcional (deve ser `null` ou `() {}`)?
- [ ] O SideMenu usa Material3 conforme redesign?
- [ ] Existe animação de entrada/saída no SideMenu ou é transição brusca?
- [ ] O SideMenu fecha corretamente ao navegar para uma rota?

### 2.5 Telas de módulos — Estados vazios e erros

Para cada tela listada, verificar:

```bash
find lib/ -name "*_screen.dart" -o -name "*_page.dart" | sort
```

Para cada arquivo encontrado, ler e responder:

**Checklist por tela:**
- [ ] Existe tratamento de estado `loading` (shimmer ou CircularProgressIndicator)?
- [ ] Existe tratamento de estado `error` (mensagem + botão retry)?
- [ ] Existe tratamento de estado `empty` (lista vazia com mensagem amigável)?
- [ ] O estado vazio não mostra lista em branco sem feedback visual?
- [ ] Textos longos usam `overflow: TextOverflow.ellipsis` ou `softWrap`?
- [ ] Imagens têm `errorBuilder` (fallback se imagem falhar ao carregar)?
- [ ] Listas usam `ListView.builder` (lazy) em vez de `ListView` com children?
- [ ] Existe `SingleChildScrollView` + `Column` com muitos filhos (anti-padrão de performance)?

---

## STEP 3 — AUDITORIA DE PERFORMANCE E REBUILDS

### 3.1 Análise de providers — consumo

```bash
# Verificar providers com watch desnecessário (sem .select)
grep -rn "ref\.watch(" lib/ --include="*.dart" | grep -v ".g.dart" | grep -v "_test.dart"
```

**Checklist performance providers:**
- [ ] Algum `ref.watch(provider)` consome um provider grande quando só precisa de um campo? (deveria usar `.select()`)
- [ ] Providers de lista (ex: lista de clientes, agenda) são re-assistidos em widgets folha que precisariam de apenas 1 item?
- [ ] Existe `ref.watch` dentro de callbacks `onPressed` ou `onTap`? (deveria ser `ref.read`)
- [ ] Algum provider `autoDispose` está sendo `keepAlive` sem justificativa?

### 3.2 Análise de widgets

```bash
# Widgets sem const onde deveriam ter
grep -rn "return Container(" lib/ --include="*.dart" | grep -v "const Container"
grep -rn "return Padding(" lib/ --include="*.dart" | grep -v "const Padding"
grep -rn "return SizedBox(" lib/ --include="*.dart" | grep -v "const SizedBox"
grep -rn "new Text(" lib/ --include="*.dart"
```

**Checklist widgets:**
- [ ] Widgets stateless sem parâmetros variáveis estão declarados `const`?
- [ ] Existe `AnimatedBuilder` ou `AnimationController` sem `dispose()`?
- [ ] Existe `TextEditingController` sem `dispose()`?
- [ ] Existe `ScrollController` sem `dispose()`?
- [ ] Existe `FocusNode` sem `dispose()`?

### 3.3 Imagens e assets

```bash
find lib/ -name "*.dart" -exec grep -l "Image\." {} \; | sort
grep -rn "Image\.network\|Image\.file\|Image\.asset" lib/ --include="*.dart"
```

**Checklist imagens:**
- [ ] `Image.network` usa `cacheWidth`/`cacheHeight` para evitar decode de imagem em resolução original?
- [ ] `Image.file` (fotos de campo) tem `gaplessPlayback: true`?
- [ ] Existe `CircleAvatar` carregando imagem de rede sem cache explícito?
- [ ] Listas com fotos usam `cached_network_image` ou equivalente?

---

## STEP 4 — AUDITORIA DE SEGURANÇA E ISOLAMENTO

### 4.1 Isolamento de user_id nos módulos

```bash
# Verificar user_id em queries SQLite por módulo
grep -rn "user_id\|userId\|producerId\|producer_id" lib/modules/ --include="*.dart" \
  | grep -v "_test.dart" | sort

# Verificar se relatorios/ tem user_id
grep -rn "user_id\|userId" lib/modules/consultoria/relatorios/ --include="*.dart"
grep -rn "user_id\|userId" lib/modules/consultoria/relatorio_visita/ --include="*.dart"
grep -rn "user_id\|userId" lib/modules/consultoria/reports/ --include="*.dart"
```

**Checklist segurança:**
- [ ] `relatorios/` tem `user_id` em todas as queries de leitura? (flagged como risco crítico)
- [ ] `relatorio_visita/` tem `user_id` em todas as queries?
- [ ] `reports/` tem `user_id` em todas as queries?
- [ ] `publicacoes/` tem `user_id` em todas as queries?
- [ ] `marketing/` tem `user_id` em todas as queries?
- [ ] Existe alguma query SQLite com `SELECT * FROM tabela` sem filtro de usuário?
- [ ] Dados de um usuário podem vazar para outro após logout/troca de conta?

### 4.2 Dados em memória após logout

```bash
grep -rn "onAuthStateChange\|signOut\|logout" lib/ --include="*.dart"
```

**Checklist logout:**
- [ ] Ao fazer logout, providers com `keepAlive` são invalidados?
- [ ] Caches em memória (listas, mapas) são limpos ao trocar de conta?
- [ ] O `router_notifier.dart` redireciona corretamente após logout?

---

## STEP 5 — AUDITORIA DE NAVEGAÇÃO MAP-FIRST

```bash
cat lib/core/router/router_notifier.dart
find lib/ -name "app_router.dart" -o -name "app_router.g.dart"

# Verificar uso proibido de Navigator.pop
grep -rn "Navigator\.pop\|context\.pop\|Navigator\.push\|context\.push" lib/ \
  --include="*.dart" | grep -v "_test.dart"

# Verificar context.go correto
grep -rn "context\.go\(" lib/ --include="*.dart" | grep -v "_test.dart"

# Verificar sub-rotas proibidas de /map
grep -rn "'/map/" lib/ --include="*.dart"
```

**Checklist navegação:**
- [ ] Existe algum `Navigator.pop()` fora de dialogs/sheets? (proibido — deve ser `context.go`)
- [ ] Existe algum `Navigator.push()` para navegação entre telas principais?
- [ ] Existe sub-rota `/map/algo` declarada no router?
- [ ] O `router_notifier.dart` tem `_isInitializing = true` zerado corretamente?
- [ ] Deep links `soloforte://reset-password` e `soloforte://login` estão nos Redirect URLs do Supabase?

---

## STEP 6 — AUDITORIA DE CÓDIGO MORTO E HIGIENE

### 6.1 Imports não utilizados

```bash
flutter analyze 2>&1 | grep "unused_import\|Unused import"
flutter analyze 2>&1 | grep "dead_code\|unreachable"
flutter analyze 2>&1 | grep "unused_element\|unused_field\|unused_local"
```

### 6.2 Arquivos órfãos (declarados mas sem referência)

```bash
# Verificar arquivos .dart não importados por ninguém
find lib/ -name "*.dart" | grep -v ".g.dart" | while read f; do
  base=$(basename "$f")
  count=$(grep -rl "$base\|$(basename $f .dart)" lib/ --include="*.dart" | grep -v "$f" | wc -l)
  if [ "$count" -eq 0 ]; then
    echo "ORPHAN: $f"
  fi
done
```

### 6.3 Constantes duplicadas

```bash
# Valores magic number repetidos (cores, paddings hardcoded)
grep -rn "EdgeInsets\.all(16\|EdgeInsets\.all(8\|EdgeInsets\.all(12" lib/ \
  --include="*.dart" | wc -l

# Cores hardcoded fora do tema
grep -rn "Color(0x\|Colors\." lib/ --include="*.dart" \
  | grep -v "theme\|Theme\|_test" | wc -l

# Strings hardcoded que deveriam ser constantes
grep -rn '"soloforte\|"SoloForte\|"Agronomo\|"Agrônomo' lib/ --include="*.dart" \
  | grep -v "_test.dart"
```

**Checklist higiene:**
- [ ] Existem arquivos `.dart` declarados mas nunca importados?
- [ ] Existem `EdgeInsets` hardcoded que deveriam usar constantes do Design System?
- [ ] Existem `Color()` hardcoded fora do `ThemeData`?
- [ ] Existem `print()` em código de produção?
- [ ] `publicacao_editor_screen.dart` tem o warning pré-existente documentado — qual é exatamente?
- [ ] Os ~45 infos de deprecação Flutter 3.27 — quais são os mais frequentes?

---

## STEP 7 — AUDITORIA DE DATABASE E OFFLINE-FIRST

```bash
cat lib/core/database/database_helper.dart
```

**Checklist database:**
- [ ] Schema está em v27 (conforme memória) ou v16 (conforme BASELINE_REAL.md)? → RESOLVER DIVERGÊNCIA
- [ ] Todas as migrações são idempotentes (`IF NOT EXISTS` / `ALTER TABLE ... IF NOT EXISTS`)?
- [ ] Existe transação (`transaction`) em operações de múltiplas tabelas?
- [ ] `ndvi_cache` tem os campos corretos: `field_id`, `image_date`, `ndvi_min/max/mean`, `sync_status`?
- [ ] Existe `index` nas colunas mais consultadas (`user_id`, `field_id`, `created_at`)?
- [ ] `sync_orchestrator.dart` trata falha de rede sem lançar exception para a UI?
- [ ] Alguma operação de sync acontece em `build()` ou `initState()`? (anti-padrão)

---

## STEP 8 — AUDITORIA DE TESTES

```bash
# Estado atual dos testes
flutter test --no-pub 2>&1 | tail -20

# Testes por módulo
find test/ -name "*_test.dart" | sort
find lib/ -name "*_test.dart" | sort   # testes fora de test/

# Cobertura de controllers críticos
find test/ -name "*controller*" -o -name "*notifier*" | grep "_test" | sort
```

**Checklist testes:**
- [ ] 69/69 testes consultoria passando? (era 67, virou 69 após fix auth)
- [ ] 268/268 testes drawing passando?
- [ ] 32 testes auth passando?
- [ ] Algum teste com `sleep()` ou `Future.delayed()` desnecessário (torna suite lenta)?
- [ ] Testes de `relatorio_visita/` e `reports/` existem? (módulos sem ADR)
- [ ] `DrawingRemoteStore` stub tem teste que verifica comportamento do stub?

---

## STEP 9 — CONSOLIDAÇÃO: RELATÓRIO DE FINDINGS

Após executar todos os STEPs acima, o agente deve preencher esta tabela:

### 🔴 CRÍTICO — Bloqueia App Store ou causa perda de dados

| # | Finding | Arquivo | Evidência | Ação recomendada |
|---|---------|---------|-----------|-----------------|
| C1 | `relatorios/` sem user_id isolation | `relatorios/` | grep sem user_id em query | Criar ADR + fix antes de submit |
| C2 | Supabase Redirect URLs não confirmados | Supabase dashboard | Documentado em memória | Confirmar soloforte://reset-password e soloforte://login |
| C3 | Build 72 não confirmado no TestFlight | Apple Transporter | Documentado em memória | Verificar status no App Store Connect |
| C4 | Divergência de versão DB (v16 vs v27) | `database_helper.dart` | BASELINE_REAL diz v16, memória diz v27 | Confirmar versão real com grep |
| _Adicionar findings encontrados_ | | | | |

### 🟠 ALTO — Afeta UX ou estabilidade

| # | Finding | Arquivo | Evidência | Ação recomendada |
|---|---------|---------|-----------|-----------------|
| A1 | `dynamic` duck typing em `_MarketingCaseCard` | `relatorios_page.dart` | Documentado em BASELINE | Tipar explicitamente com `MarketingCase` |
| A2 | `private_map_screen.dart` próximo de 904 linhas | `private_map_screen.dart` | Governança ativa | Decompor em widgets menores |
| A3 | Dois módulos `agenda/` coexistindo | `modules/agenda/` + `consultoria/agenda/` | BASELINE_REAL | Consolidar com ADR |
| A4 | ADR-027 F2 e F3 pendentes (18 arquivos sem migração) | Grupo A e B | Memória | Executar migração |
| _Adicionar findings encontrados_ | | | | |

### 🟡 MÉDIO — Dívida técnica aceitável mas documentada

| # | Finding | Arquivo | Evidência | Ação recomendada |
|---|---------|---------|-----------|-----------------|
| M1 | `reports/` e `relatorio_visita/` sem ADR formal | Respectivos | BASELINE_REAL | Criar ADR-018 e ADR-019 |
| M2 | `visitas/`, `drawing/`, `feedback/`, `dashboard/` sem ADR | Respectivos | BASELINE_REAL | Documentar quando tocar |
| M3 | `ArmedMode` vs `MapContext` não resolvido | Indefinido | Memória | Resolver com ADR |
| M4 | `DrawingRemoteStore` apenas stub | `drawing/` | Memória | Implementar ou documentar prazo |
| M5 | Warning em `publicacao_editor_screen.dart` | Arquivo | `flutter analyze` | Avaliar e corrigir |
| _Adicionar findings encontrados_ | | | | |

### 🟢 BAIXO — Higiene e melhoria contínua

| # | Finding | Arquivo | Evidência | Ação recomendada |
|---|---------|---------|-----------|-----------------|
| L1 | ~45 infos de deprecação Flutter 3.27 | Vários | `flutter analyze` | Planejar sprint de higiene |
| L2 | Comentário pendente em `app_shell.dart` linha 13 | `app_shell.dart` | Memória | Adicionar comentário de documentação |
| L3 | `print()` em produção (se encontrados) | A identificar | grep | Remover ou trocar por `debugPrint` |
| L4 | Widgets sem `const` onde possível | A identificar | grep | Adicionar `const` progressivamente |
| _Adicionar findings encontrados_ | | | | |

---

## STEP 10 — PRIORIZAÇÃO PARA PRÓXIMOS PROMPTS

Com base nos findings, o agente deve sugerir a ordem de execução:

```
SPRINT IMEDIATO (antes de App Store):
1. [ ] Confirmar Build 72 no TestFlight
2. [ ] Confirmar Redirect URLs no Supabase
3. [ ] Fix user_id isolation em relatorios/ (se confirmado ausente)

SPRINT 1 (pós-TestFlight):
4. [ ] ADR-026 IVisitWriter (desbloqueado após TestFlight)
5. [ ] ADR-027 F2 (Grupo A — 11 arquivos)
6. [ ] ADR-027 F3 (Grupo B — 7 arquivos)

SPRINT 2 (qualidade):
7. [ ] Corrigir dynamic duck typing em _MarketingCaseCard
8. [ ] Decompor private_map_screen.dart (se > 900 linhas)
9. [ ] Consolidar módulos agenda/ com ADR

SPRINT 3 (higiene):
10. [ ] Higiene Flutter 3.27 deprecations
11. [ ] Adicionar const progressivamente
12. [ ] Documentar ADR-018/019 para reports/ e relatorio_visita/
```

---

## VALIDAÇÃO FINAL DO PROMPT

| Pergunta | Resposta esperada |
|----------|------------------|
| Este prompt alterou algum arquivo? | NÃO — somente leitura |
| Este prompt criou dados fictícios? | NÃO |
| Este prompt extrapolou o escopo? | NÃO — auditoria geral autorizada |
| O agente deve parar se encontrar violação crítica? | SIM — reportar antes de continuar |
| A execução é obrigatória imediata? | NÃO — agente pode sugerir e aguardar aprovação |

---

## ENCERRAMENTO

> Este prompt de auditoria cobre:
> - Duplicações de módulos e arquivos
> - Bugs de UI (estados vazios, overflow, sheets)
> - Performance (rebuilds, const, providers)
> - Segurança (user_id isolation, logout)
> - Navegação Map-First (violações de rota)
> - Código morto e higiene
> - Database e offline-first
> - Testes e cobertura
> - Findings priorizados com ação clara

> **Nenhum arquivo do SoloForte foi alterado neste prompt.**
> Todos os findings devem ser confirmados com grep/leitura real antes de qualquer ação.
