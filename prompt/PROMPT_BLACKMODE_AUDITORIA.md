# PROMPT — AUDITORIA: MODO BLACK + AZUL SAMSUNG
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria (READ-ONLY)  
**Tipo:** AUDITORIA VISUAL/TEMA — ZERO EDIÇÃO  
**Contrato de referência:** `.cursor/rules/soloforte-blackmode.mdc`  
**Risco:** Nenhum — apenas leitura e reporte

---

## OBJETIVO

Mapear, arquivo por arquivo em `lib/`, onde o contrato do modo **Black**
(`.cursor/rules/soloforte-blackmode.mdc`) está sendo violado.

Entregar um relatório estruturado que permita, na fase seguinte, gerar prompts
de correção cirúrgica por tela — **sem editar código nesta etapa**.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo  
❌ Não criar nenhum arquivo (exceto o relatório de saída solicitado abaixo)  
❌ Não sugerir implementação ou refatoração durante esta etapa  
❌ Não tocar em `MarketingCase`, rotas ou lógica de negócio

---

## CONTRATO A VALIDAR (resumo)

| Token | Valor esperado |
|---|---|
| `background.primary` | `#0D0D0D` |
| `background.surface` | `#1C1C1E` |
| `background.surfaceAlt` | `#242426` |
| `border.divider` | `#2C2C2E` |
| `text.primary` | `#FFFFFF` |
| `text.secondary` | `#A0A0A5` |
| `text.disabled` | `#5C5C5E` |
| `accent.secondary` (Azul Samsung) | `#1428A0` |
| `accent.secondaryVariant` | `#0F1E7A` |
| `status.error` | `#FF3B30` |

**Regra de acento:** no modo Black, ícones ativos, FAB, abas selecionadas,
bordas de foco e checkmarks devem usar `#1428A0` — **não** verde da marca
como acento secundário dentro do Black.

---

## PASSO 0 — FONTE DA VERDADE DO TEMA

```bash
find lib/ -path "*theme*" -name "*.dart" | sort
rg -l "blackTheme|themeFor|getTheme|AppThemes|PremiumAppTheme|PremiumTokens" lib/
```

Ler e reportar o estado atual de:

- `lib/modules/settings/presentation/theme/app_themes.dart`
- `lib/ui/theme/premium/premium_app_theme.dart`
- `lib/ui/theme/premium/design_tokens.dart`

Para cada arquivo, documentar:

1. Valores atuais de `scaffoldBackgroundColor`, `colorScheme.primary/secondary/surface`
2. Divergências em relação à paleta oficial (ex.: gold `#D4AF37` vs azul `#1428A0`)
3. Se `backgroundDark` usa `#000000` em vez de `#0D0D0D`
4. Se existe extensão `PremiumThemeAware` e onde é (ou não é) consumida

---

## PASSO 1 — INVENTÁRIO DE TELAS (ROTAS + PÁGINAS)

```bash
rg -n "GoRoute|context\.(go|push)\(" lib/core/router/ | head -80
find lib/modules -name "*_page.dart" -o -name "*_screen.dart" | sort
find lib/ui/screens -name "*.dart" | sort
```

Gerar tabela:

| Módulo | Arquivo | Rota (se houver) | Na lista de evidência visual? |
|---|---|---|---|

Marcar quais telas da seção 4 do contrato (`soloforte-blackmode.mdc`) foram
encontradas e quais estão ausentes ou renomeadas.

---

## PASSO 2 — BUSCA SISTEMÁTICA DE VIOLAÇÕES

Executar e consolidar resultados por módulo:

```bash
# Fundos claros hardcoded
rg -n "Colors\.white|Color\(0xFF[Ff]{6}\)|Color\(0xFFFFFFFF\)" lib/ \
  --glob "!**/*_test.dart" --glob "!**/*.g.dart"

# Preto puro hardcoded (deve ser token do tema)
rg -n "Color\(0xFF000000\)|Colors\.black[^.]" lib/ \
  --glob "!**/*_test.dart"

# Texto escuro sobre fundo que deveria ser claro no Black
rg -n "Colors\.black87|Colors\.black54|Colors\.black45|Colors\.black12" lib/

# Acentos verdes usados como seleção (candidatos a Azul Samsung no Black)
rg -n "brandGreen|0xFF34C759|0xFF4ADE80|primaryColor" lib/ \
  --glob "!**/design_tokens.dart" --glob "!**/app_themes.dart"

# Tokens de módulo que ignoram tema
rg -n "const k[A-Z].*= Colors\.|static const Color" lib/modules/
```

Para cada ocorrência relevante (ignorar overlays de modal `Colors.black.withValues`):

- Arquivo + linha
- Widget/contexto (Scaffold, Card, segmented control, etc.)
- Tipo de violação: `HARD_BG_LIGHT` | `HARD_TEXT_DARK` | `WRONG_ACCENT` | `IGNORES_THEME` | `TOKEN_MODULE`
- Severidade: `BLOCKER` (tela inteira clara) | `MAJOR` (componente visível) | `MINOR` (detalhe)

---

## PASSO 3 — AUDITORIA POR CONTEXTO (EVIDÊNCIA VISUAL)

Validar cada contexto abaixo com leitura de código. Não assumir caminhos —
usar `find`/`rg` primeiro.

### 3.1 Configurações (`lib/modules/settings/`)

```bash
find lib/modules/settings -name "*.dart" | sort
rg -n "Colors\.|Color\(0x" lib/modules/settings/presentation/
```

Foco: Aparência (seleção Verde/Azul/Black), Perfil, Dados offline, Sessão.

### 3.2 SideMenu (`lib/ui/components/side_menu_overlay.dart`)

```bash
rg -n "Colors\.|Color\(0x|Theme\.of" lib/ui/components/side_menu_overlay.dart
```

Foco: ícone ativo, fundo do menu, texto secundário.

### 3.3 Agenda (`lib/modules/agenda/`)

```bash
rg -n "TabBar|Segmented|Colors\.|Color\(0x" lib/modules/agenda/presentation/
```

Foco: abas Calendário / Planejamento / Indicadores.

### 3.4 Carteira (`lib/modules/carteira/`)

```bash
rg -n "Colors\.|Color\(0x|isSelected" lib/modules/carteira/presentation/
```

Foco: `carteira_segment_bar.dart`, toggles segmentados, categorias Químico/Fertilizante.

### 3.5 Clima (`lib/modules/clima/`)

```bash
rg -n "Colors\.|Color\(0x|kClima" lib/modules/clima/
```

Foco: `clima_tokens.dart` — reportar se `kClimaCard = Colors.white` ignora Black.

### 3.6 Feedback (`lib/modules/feedback/`)

```bash
rg -n "Colors\.|Color\(0x|Card\(" lib/modules/feedback/presentation/
```

Foco: cards Bug/Sugestão/Elogios, gráfico "Sugestões por módulo".

### 3.7 Sheets globais

```bash
rg -n "Colors\.|Color\(0x|backgroundColor" lib/core/ui/sheets/
```

Foco: `soloforte_sheet.dart`, `sheet_tokens.dart` — conformidade com superfícies escuras.

---

## PASSO 4 — FAB E COMPONENTES GLOBAIS

```bash
rg -n "Color\(|Theme\.of|brightness" lib/ui/components/smart_button.dart
rg -n "PremiumThemeAware|premiumBackground|premiumSurface" lib/
```

Reportar:

1. Se `smart_button.dart` reage ao modo Black (somente leitura — arquivo é imutável na correção, mas a auditoria deve registrar o estado atual).
2. Quantas telas usam `PremiumThemeAware` vs `PremiumTokens.*Light` fixo.
3. Lista de arquivos que usam `PremiumTokens.backgroundLight` / `surfaceLight` diretamente.

---

## PASSO 5 — PROVIDER DE APARÊNCIA

```bash
rg -l "themeMode|appearance|AppTheme|selectedTheme|themeProvider" lib/
```

Documentar:

- Onde a preferência Verde/Azul/Black é persistida
- Qual `ThemeData` é aplicado na raiz (`MaterialApp` / `ProviderScope`)
- Se a troca de tema propaga via `ref.watch` sem precisar restart

---

## FORMATO DO RELATÓRIO DE SAÍDA

Salvar em: `prompt/BLACKMODE_AUDITORIA_RELATORIO.md`

Estrutura obrigatória:

```markdown
# Relatório — Auditoria Modo Black
Data: YYYY-MM-DD
SHA: <git rev-parse --short HEAD>

## 1. Resumo executivo
- Total de arquivos com violação
- BLOCKER / MAJOR / MINOR
- Top 5 telas mais críticas

## 2. Estado do tema central
(tabela: arquivo → valor atual → valor esperado → gap)

## 3. Violações por módulo
### settings
| Arquivo | Linha | Violação | Severidade | Nota |
...

## 4. Contextos da evidência visual — status
| Contexto | Arquivo(s) | Status | Observação |
| OK | PARCIAL | BLOCKER |

## 5. Recomendação de ordem de correção (sem implementar)
Fase A: tema central + tokens
Fase B: settings + side menu
Fase C: carteira + agenda + clima + feedback
...

## 6. Riscos e dependências
- smart_button.dart imutável → como aplicar azul sem editar?
- PremiumTokens vs ColorScheme — qual fonte única?
```

---

## CRITÉRIO DE CONCLUSÃO DA AUDITORIA

A auditoria só está completa quando:

1. Todos os arquivos em `lib/modules/settings/`, `carteira/`, `agenda/`, `clima/`, `feedback/` e `side_menu_overlay.dart` foram verificados.
2. O relatório lista **cada** ocorrência `BLOCKER` e `MAJOR` com arquivo + linha.
3. O gap entre `app_themes.dart` / `premium_app_theme.dart` e a paleta oficial está documentado.
4. Nenhum arquivo de código foi alterado.

---

## GATE PARA FASE 2 (CORREÇÃO)

⛔ Não gerar prompt de correção até o usuário aprovar explicitamente
`prompt/BLACKMODE_AUDITORIA_RELATORIO.md`.

Após aprovação, a correção deve:

- Citar `.cursor/rules/soloforte-blackmode.mdc` em cada PR
- Ser por tela/módulo, com `./tool/arch_check.sh` → Exit 0
- Não alterar comportamento fora do escopo visual Black
