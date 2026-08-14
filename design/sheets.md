# PROMPT CIRÚRGICO — feat: SheetSkin iOS para Tema Azul

**Agente:** Engenheiro Sênior Flutter/Dart — Top 0,1% **Módulos tocados:** `core/ui/sheets/` + `ui/theme/premium/premium_app_theme.dart` **Tipo:** feature · skin condicional por tema ativo · ThemeExtension semântica **Risco:** Baixo **Versão base:** v1.34.0+189 · arch_check Exit 0 **Restore point:** `restore/sheet-skin-ios-pre` · SHA `2685139`

---

## CONTEXTO CONFIRMADO (Gate 1 + Gate 2 — já auditados)


| Item                     | Valor real                                                            |
| ------------------------ | --------------------------------------------------------------------- |
| Provider de tema         | `themeProvider` → `StateNotifierProvider<ThemeNotifier, String>`      |
| Valor azul               | `'blue'`                                                              |
| Arquivo provider         | `lib/modules/settings/presentation/providers/settings_providers.dart` |
| Leitura em widget        | `ref.watch(themeProvider)`                                            |
| Restrição arch           | `core/` NÃO pode importar `modules/settings/`                         |
| Solução de detecção      | `ThemeExtension<SoloForteThemeExtension>` em `premium_app_theme.dart` |
| Chamadores               | 12 arquivos (listados abaixo)                                         |
| Variante atual em tokens | Nenhuma — só `SoloForteSheetTokens` escuro fixo                       |
| arch_check               | ✅ Exit 0                                                              |


**12 chamadores (não tocar nenhum):**

```
lib/modules/auth/widgets/profile_avatar_picker.dart
lib/modules/map/presentation/widgets/visit_active_card.dart
lib/modules/settings/presentation/screens/settings_screen.dart
lib/modules/marketing/presentation/widgets/marketing_case_sheet.dart
lib/modules/agenda/presentation/pages/agenda_month_page.dart
lib/ui/screens/widgets/plano_block_sheet.dart
lib/ui/screens/map/handlers/novo_case_modal_launcher.dart
lib/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart
lib/ui/screens/map/controllers/map_sheet_controller.dart
lib/ui/components/map/publicacao_pin_preview.dart
lib/ui/components/public_map/public_publication_preview.dart
lib/core/ui/sheets/soloforte_sheet.dart (definição)

```

---

## OBJETIVO

Quando `themeId == 'blue'` (lido via `SoloForteThemeExtension`), o `showSoloForteSheet` aplica automaticamente a skin iOS leve: fundo prata `#F5F6F8`, card azulado interno, handle azul, ícones circulares, botão CTA azul Flutter, botão ghost "Cancelar". Verde e Black mantêm comportamento 100% atual. **Zero alteração nos 12 chamadores.**

---

## ARQUIVOS A TOCAR (apenas estes 3)

```
lib/ui/theme/premium/premium_app_theme.dart   ← adicionar SoloForteThemeExtension
lib/core/ui/sheets/sheet_tokens.dart          ← adicionar bloco SheetSkinIos
lib/core/ui/sheets/soloforte_sheet.dart       ← skin condicional via ThemeExtension

```

---

## GATE 3A — ThemeExtension (premium_app_theme.dart)

### Sugestão do agente ANTES de escrever

O agente deve apresentar o pseudocódigo da extensão para aprovação. Pseudocontrato esperado:

```
// NOVO — adicionar em premium_app_theme.dart

class SoloForteThemeExtension
    extends ThemeExtension<SoloForteThemeExtension> {

  final String themeId; // 'green' | 'blue' | 'black'

  const SoloForteThemeExtension({required this.themeId});

  @override
  SoloForteThemeExtension copyWith({String? themeId}) =>
      SoloForteThemeExtension(themeId: themeId ?? this.themeId);

  @override
  SoloForteThemeExtension lerp(
      ThemeExtension<SoloForteThemeExtension>? other, double t) =>
      t < 0.5 ? this : (other as SoloForteThemeExtension? ?? this);
}

// Em PremiumAppTheme.themeFor(String mode):
// Dentro do ThemeData de cada tema, adicionar:
//   extensions: [SoloForteThemeExtension(themeId: mode)]
//
// Exemplo:
//   themeFor('blue')  → extensions: [SoloForteThemeExtension(themeId: 'blue')]
//   themeFor('green') → extensions: [SoloForteThemeExtension(themeId: 'green')]
//   themeFor('black') → extensions: [SoloForteThemeExtension(themeId: 'black')]

```

### Leitura em qualquer widget (incluindo core/)

```
// Detecção — sem importar modules/settings/
final ext = Theme.of(context).extension<SoloForteThemeExtension>();
final bool isIosBlueSkin = ext?.themeId == 'blue';

```

### Restrições

- ❌ Não alterar nenhuma cor, brightness, shape ou tipografia dos temas
- ❌ Não alterar assinatura de `themeFor()`
- ✅ Apenas adicionar a classe + registrar `extensions: [...]` em cada tema
- ✅ Se `extensions` já existir no ThemeData → fazer append, não substituir

> ⛔ **GATE 3A** — Mostrar o diff exato de `premium_app_theme.dart` antes de salvar. Confirmar que nenhuma cor, brightness ou shape foi alterada.

---

## GATE 3B — Tokens iOS (sheet_tokens.dart)

Adicionar classe `SoloForteSheetSkinIos` dentro de `sheet_tokens.dart`. **Não remover nem alterar** `SoloForteSheetTokens` **existente.**

```
// NOVO — adicionar após SoloForteSheetTokens existente

abstract class SoloForteSheetSkinIos {

  // Fundo principal do sheet
  static const Color background     = Color(0xFFF5F6F8); // prata suave iOS 17

  // Card interno agrupado
  static const Color cardBackground = Color(0xFFEBF5FF);
  static const Color cardBorder     = Color(0xFFB3D9F5);
  static const double cardRadius    = 14.0;

  // Handle
  static const Color handleColor    = Color(0xFF7EC8F0);
  static const Size  handleSize     = Size(40, 4);

  // Borda superior do sheet
  static const Color sheetBorder    = Color(0xFFB3D9F5);
  static const double sheetRadius   = 22.0;

  // Ícones — circulares
  static const Color iconBackground = Color(0xFFB3D9F5);
  static const Color iconStroke     = Color(0xFF0175C2);
  static const double iconRadius    = 999.0; // circular

  // Textos
  static const Color titleColor     = Color(0xFF003D6B);
  static const Color subtitleColor  = Color(0xFF1A8FD1);
  static const Color arrowColor     = Color(0xFF0175C2);

  // Badge role (ex: "consultor")
  static const Color badgeBackground = Color(0xFFD0EEFB);
  static const Color badgeText       = Color(0xFF0175C2);
  static const Color badgeBorder     = Color(0xFF7EC8F0);

  // Botão CTA principal
  static const Color ctaBackground  = Color(0xFF0175C2); // Flutter Blue
  static const Color ctaText        = Color(0xFFFFFFFF);
  static const double ctaRadius     = 13.0;

  // Botão ghost (Cancelar)
  static const Color ghostBorder    = Color(0xFF7EC8F0);
  static const Color ghostText      = Color(0xFF0175C2);
  static const double ghostRadius   = 13.0;

  // Separador entre rows do card
  static const Color rowDivider     = Color(0x1A0175C2); // 10% opacity
}

```

> ⛔ **GATE 3B** — Mostrar o bloco acima inserido no contexto do arquivo (linhas antes e depois) antes de salvar.

---

## GATE 4 — Wrapper (soloforte_sheet.dart)

### Mecanismo — InheritedWidget SoloForteSheetSkin

Como `showSoloForteSheet` é uma função top-level (não Widget com `build()`), a skin deve ser injetada via `InheritedWidget` no topo do builder, consumida pelos widgets internos do sheet automaticamente.

Pseudocontrato:

```
// 1. Criar InheritedWidget (dentro de soloforte_sheet.dart ou arquivo novo
//    em core/ui/sheets/):

class SoloForteSheetSkinScope extends InheritedWidget {
  final bool isIos;
  const SoloForteSheetSkinScope({
    required this.isIos,
    required super.child,
    super.key,
  });

  static SoloForteSheetSkinScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoloForteSheetSkinScope>();

  @override
  bool updateShouldNotify(SoloForteSheetSkinScope old) =>
      old.isIos != isIos;
}

// 2. Em showSoloForteSheet(), dentro do builder:

builder: (context) {
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  final bool isIos = ext?.themeId == 'blue';

  return SoloForteSheetSkinScope(
    isIos: isIos,
    child: _SoloForteSheetChrome(
      isIos: isIos,
      child: child, // builder do chamador — não muda
    ),
  );
}

// 3. _SoloForteSheetChrome — widget privado que aplica o chrome do sheet:

// Se isIos == true:
//   backgroundColor: SoloForteSheetSkinIos.background
//   borderRadius: SoloForteSheetSkinIos.sheetRadius (top)
//   handle: SoloForteSheetSkinIos.handleColor, tamanho 40×4
//   borda superior: SoloForteSheetSkinIos.sheetBorder
//
// Se isIos == false:
//   → comportamento atual (SoloForteSheetTokens existente) — sem alteração

```

### O que widgets internos de core/ui/sheets/widgets/ fazem

Widgets como `sheet_section_header.dart`, `sheet_input_field.dart`, `sheet_chip_selector.dart` — se existirem — podem ler `SoloForteSheetSkinScope.of(context)?.isIos` para ajustar ícones e cores. **Somente se já existirem nessa pasta.** Não criar novos widgets de UI.

### Restrições absolutas

- ❌ Não alterar assinatura de `showSoloForteSheet()`
- ❌ Não adicionar parâmetro obrigatório
- ❌ Não tocar nos 12 chamadores
- ❌ Não alterar comportamento quando `isIos == false`
- ✅ `_SoloForteSheetChrome` é widget privado — não exportado

> ⛔ **GATE 4** — Mostrar diff completo de `soloforte_sheet.dart` (e arquivo do InheritedWidget se separado) antes de salvar. Confirmar que assinatura pública não mudou.

---

## GATE 5 — Validação final

```bash
# 1. Arch check — Exit 0 obrigatório
./tool/arch_check.sh

# 2. Analyze — zero erros novos
flutter analyze lib/ 2>&1 | grep -E "^  error|^  warning"

# 3. Testes — nenhum novo failing
flutter test 2>&1 | tail -5

# 4. Chamadores intocados — lista idêntica ao Gate 1
rg "showSoloForteSheet\|SoloforteSheet" lib/ --include="*.dart" -l | sort

# 5. Extensão registrada nos 3 temas
rg "SoloForteThemeExtension" lib/ --include="*.dart" -n
# deve aparecer: green, blue, black

# 6. Smoke test manual (device ou emulator)
# → Abrir app com tema Verde → abrir qualquer sheet → visual igual ao atual
# → Trocar para Azul → abrir sheet → fundo prata, card azulado, handle azul
# → Trocar para Black → abrir sheet → visual igual ao atual

```

> ⛔ **GATE 5** — Compartilhar output de todos os comandos antes do commit.

---

## CHECKLIST DE VALIDAÇÃO FINAL

```
[ ] arch_check.sh → Exit 0?                        SIM
[ ] flutter analyze → zero erros novos?             SIM
[ ] Testes → nenhum novo failing?                   SIM
[ ] SoloForteThemeExtension registrada nos 3 temas? SIM
[ ] Chamadores do showSoloForteSheet alterados?     NÃO
[ ] Assinatura pública de showSoloForteSheet mudou? NÃO
[ ] Tema Verde alterado visualmente?                NÃO
[ ] Tema Black alterado visualmente?                NÃO
[ ] Cores/brightness/shapes dos temas alterados?    NÃO
[ ] Navegação mudou?                                NÃO
[ ] Contrato de dados alterado?                     NÃO
[ ] Providers globais alterados?                    NÃO
[ ] Módulos fora dos 3 arquivos tocados?            NÃO

```

Se qualquer NÃO virar SIM → `git reset --hard restore/sheet-skin-ios-pre`

---

## PALETA FINAL APROVADA


| Token             | Hex                 | Uso                      |
| ----------------- | ------------------- | ------------------------ |
| `background`      | `#F5F6F8`           | Fundo do sheet           |
| `cardBackground`  | `#EBF5FF`           | Card agrupado            |
| `cardBorder`      | `#B3D9F5`           | Borda do card            |
| `handleColor`     | `#7EC8F0`           | Handle                   |
| `sheetBorder`     | `#B3D9F5`           | Borda superior           |
| `iconBackground`  | `#B3D9F5`           | Fundo ícone circular     |
| `iconStroke`      | `#0175C2`           | Stroke ícone             |
| `titleColor`      | `#003D6B`           | Título do sheet          |
| `subtitleColor`   | `#1A8FD1`           | Subtexto                 |
| `ctaBackground`   | `#0175C2`           | Botão CTA (Flutter Blue) |
| `ctaText`         | `#FFFFFF`           | Texto CTA                |
| `ghostBorder`     | `#7EC8F0`           | Ghost borda              |
| `ghostText`       | `#0175C2`           | Ghost texto              |
| `badgeBackground` | `#D0EEFB`           | Badge role               |
| `badgeText`       | `#0175C2`           | Badge texto              |
| `rowDivider`      | `Color(0x1A0175C2)` | Separador rows           |


---

## RELATÓRIO ESPERADO (preencher ao concluir)

```
Arquivos tocados:
  - lib/ui/theme/premium/premium_app_theme.dart
      → classe SoloForteThemeExtension adicionada
      → extensions: [...] registrado em themeFor('green'), themeFor('blue'), themeFor('black')
  - lib/core/ui/sheets/sheet_tokens.dart
      → classe SoloForteSheetSkinIos adicionada (SoloForteSheetTokens intocado)
  - lib/core/ui/sheets/soloforte_sheet.dart
      → SoloForteSheetSkinScope (InheritedWidget) adicionado
      → _SoloForteSheetChrome (widget privado) adicionado
      → showSoloForteSheet() lê ThemeExtension e injeta skin (assinatura pública intocada)

Arquivos NÃO tocados:
  - 12 chamadores de showSoloForteSheet
  - design_tokens.dart
  - Qualquer arquivo fora dos 3 acima

Decisão arquitetural:
  - ThemeExtension semântica: detecção por themeId='blue', não por valor hex
  - InheritedWidget: skin injetada no chrome, consumível por widgets filhos
  - Retrocompatível total: isIos=false → comportamento atual preservado

Próximos passos:
  - QA visual em device físico iOS + Android (tema Azul)
  - Smoke test dos 12 chamadores com tema Azul ativo
  - Avaliar se widgets em core/ui/sheets/widgets/ precisam ler SoloForteSheetSkinScope

```

---

---

## QA — SheetSkin iOS (tema Azul) · Versão Final

**Branch:** `cursor/marketing-cliente-limite-493d`  
**Commit branch:** `6230591` · **Main:** `e04e690` (cherry-pick) · **Tag:** `feat/sheet-skin-ios`  
**Restore:** `restore/sheet-skin-ios-pre` (`2685139`)  
**Data:** 14/08/2026

### Critérios de aprovação (leia antes de testar)

| Situação | Classificação correta |
|---|---|
| Sheet com `showSoloForteSheet` sem `transparent` → chrome prata + handle azul | ✅ PASSOU |
| Sheet com `backgroundColor: transparent` → chrome não pinta fundo prata | ⚠️ LIMITAÇÃO CONHECIDA — não é FALHA |
| `MapBottomSheet` / hosts próprios do mapa → não participam do chrome | ⚠️ LIMITAÇÃO CONHECIDA — não é FALHA |
| App quebra, crash, dismiss não funciona | ❌ FALHA real |
| Visual azul/prata aparece com tema Verde ou Black | ❌ FALHA real |

### Preparação

```bash
flutter run --debug
# ou
flutter run --release
```

> Testar obrigatoriamente em **iOS físico** e **Android físico**.

---

### BLOCO 1 — Regressão (Verde e Black)

#### 1A — Tema Verde

| # | Como abrir | O que verificar | OK? |
|---|---|---|---|
| 1.1 | Abrir app com tema Verde | App carrega sem erro | |
| 1.2 | Configurações → tocar avatar | Sheet abre com visual atual (sem prata, sem azul) | |
| 1.3 | Agenda → ícone de filtro | Sheet abre com visual atual | |
| 1.4 | Marketing → abrir pin | Sheet abre com visual atual | |
| 1.5 | Mapa → iniciar visita | Sheet abre com visual atual | |
| 1.6 | Fechar sheet 3× seguidas | Sem flickering, sem crash | |

#### 1B — Tema Black

| # | Como abrir | O que verificar | OK? |
|---|---|---|---|
| 1.7 | Trocar para tema Black | App aplica tema escuro | |
| 1.8 | Configurações → tocar avatar | Sheet escuro atual — zero azul ou prata no chrome | |
| 1.9 | Agenda → ícone de filtro | Sheet escuro atual | |
| 1.10 | Ocorrência → abrir detalhe | Sheet escuro atual | |
| 1.11 | Fechar sheet e reabrir | Visual escuro estável | |

**Resultado BLOCO 1:** `PASSOU / FALHOU`  
Falhas (se houver): ___________________________

---

### BLOCO 2 — Feature (tema Azul)

#### 2A — Chrome iOS obrigatório

| # | Sheet | Como abrir | O que verificar | OK? |
|---|---|---|---|---|
| 2.1 | Configurações | Trocar para Azul → Configurações → avatar | Fundo modal `#F5F6F8` prata suave | |
| 2.2 | Configurações | Mesmo sheet | Handle azul `#7EC8F0`, tamanho 40×4, centralizado | |
| 2.3 | Configurações | Mesmo sheet | Cantos 22px (mais arredondados que antes — era 20px) | |
| 2.4 | Configurações | Mesmo sheet | Borda superior azul `#B3D9F5` visível | |
| 2.5 | Agenda filtros | Agenda → ícone filtro | Chrome modal prata + handle azul | |
| 2.6 | Agenda filtros | Mesmo sheet | Conteúdo interno pode ser escuro — não é falha | |
| 2.7 | Ocorrência detalhe | Lista → abrir ocorrência | Chrome prata + handle azul | |
| 2.8 | Plano block | Fluxo que abre plano_block_sheet | Chrome prata + handle azul | |
| 2.9 | Qualquer sheet Azul | Arrastar para fechar | Dismiss funciona normalmente | |
| 2.10 | Qualquer sheet Azul | Tap fora do sheet | Dismiss funciona normalmente | |

#### 2B — Limitações conhecidas (anotar, não marcar como FALHA)

| # | Sheet | Situação | Classificação |
|---|---|---|---|
| 2.11 | Marketing Case | `backgroundColor: transparent` — chrome não pinta prata | ⚠️ Limitação conhecida |
| 2.12 | Mapa visita (visit_active_card) | `backgroundColor: transparent` — chrome não pinta prata | ⚠️ Limitação conhecida |
| 2.13 | Ocorrência criação no mapa | Usa `MapBottomSheet`, não `showSoloForteSheet` | ⚠️ Fora do escopo |

**Resultado BLOCO 2:** `PASSOU / FALHOU`  
Falhas reais (se houver): ___________________________  
Limitações confirmadas: ___________________________

---

### BLOCO 3 — Troca dinâmica de tema

| # | Sequência | O que verificar | OK? |
|---|---|---|---|
| 3.1 | Tema **Verde** → abrir Agenda filtros | Chrome atual (sem prata) | |
| 3.2 | Fechar sheet → trocar para **Azul** | Tema aplicado na tela principal | |
| 3.3 | Abrir Agenda filtros novamente | Chrome prata + handle azul | |
| 3.4 | Fechar sheet → trocar para **Black** | Tema escuro aplicado | |
| 3.5 | Abrir Agenda filtros novamente | Chrome escuro atual — zero prata ou azul | |
| 3.6 | Fechar sheet → voltar para **Azul** | Tema azul aplicado | |
| 3.7 | Abrir Agenda filtros novamente | Chrome prata + handle azul reaparece | |
| 3.8 | Repetir sequência com sheet de Configurações | Mesmo comportamento | |

**Resultado BLOCO 3:** `PASSOU / FALHOU`  
Falhas (se houver): ___________________________

---

### BLOCO 4 — Edge cases

| # | Cenário | Como testar | O que verificar | OK? |
|---|---|---|---|---|
| 4.1 | Sheet com conteúdo longo | Abrir sheet com scroll (ex: plano_block ou agenda filtros) | Fundo prata em toda a área do modal, sem corte branco/preto no scroll | |
| 4.2 | iPhone com notch ou Dynamic Island | Device iOS físico | Handle visível e centralizado, sem sobreposição com ilha dinâmica | |
| 4.3 | Android com navbar gesture | Device Android físico | Swipe para baixo fecha o sheet normalmente | |
| 4.4 | Android com navbar botões | Device Android físico com botões de navegação | Dismiss por botão voltar funciona | |
| 4.5 | App em background com sheet aberto | Abrir sheet → Home → voltar ao app | Sheet mantém visual correto, sem reset de tema | |
| 4.6 | Abrir sheet → receber notificação push | Testar se possível | Sheet não fecha nem perde skin ao receber notificação | |
| 4.7 | Sheet em modo paisagem | Rotacionar device (se app suportar) | Sheet recompõe sem perder skin iOS | |

**Resultado BLOCO 4:** `PASSOU / FALHOU`  
Falhas (se houver): ___________________________

---

### Resultado final (colar aqui após device)

```
Device iOS testado:      _________________  iOS ____
Device Android testado:  _________________  Android ____

BLOCO 1 — Regressão Verde/Black:   PASSOU / FALHOU
BLOCO 2 — Feature Azul:            PASSOU / FALHOU
BLOCO 3 — Troca dinâmica:          PASSOU / FALHOU
BLOCO 4 — Edge cases:              PASSOU / FALHOU

Limitações conhecidas confirmadas (não são falhas):
  [ ] Marketing transparent
  [ ] Mapa visita transparent
  [ ] MapBottomSheet fora do escopo

Falhas reais encontradas:
  -

Aprovado para cherry-pick em main?   SIM / NÃO
```

---

### Após QA aprovado — cherry-pick para main

```bash
git checkout main
git pull origin main
git cherry-pick 6230591
git status
./tool/arch_check.sh
git push origin main
git tag -a feat/sheet-skin-ios -m "SheetSkin iOS: tema Azul com SoloForteThemeExtension"
git push origin feat/sheet-skin-ios
```

> ⛔ Executar somente após todos os blocos PASSOU e aprovação explícita.

### Rollback (se BLOCO 2 falhar além das limitações conhecidas)

```bash
git reset --hard restore/sheet-skin-ios-pre
git push origin cursor/marketing-cliente-limite-493d --force
```

### Fase 2 — agendada (fora deste escopo)

- `core/ui/sheets/widgets/` → widgets internos leem `SoloForteSheetSkinScope.of(context)`
- Conteúdo interno adota tokens iOS quando `isIos == true`
- Zero alteração nos 12 chamadores externos

---

*SoloForte v1.34.0+189 · 14/08/2026*  
*Commit branch: 6230591 · Main: e04e690 · Tag: feat/sheet-skin-ios*  
*Restore: restore/sheet-skin-ios-pre · SHA 2685139*