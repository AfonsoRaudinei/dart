# Auditoria de regressão — IPA 210

**Data:** 15/Ago/2026  
**Versão:** `1.34.0+210`  
**SHA de referência (main):** `78d32f2`  
**IPA anterior:** `209` @ `ddf7f56`  
**Status:** regressões documentadas · blindagem em andamento

---

## Veredito executivo

O módulo **Relatórios não foi alterado** entre IPA 209 e IPA 210. Zero arquivos em `lib/modules/consultoria/relatorios/` no delta `ddf7f56..78d32f2`.

As regressões visíveis em Relatórios (e em Marketing, Agenda, Carteira, Clientes, etc.) são **efeito colateral** de mudança no kernel compartilhado `showSoloForteSheet` (SheetSkin iOS Fase 2), não de bug local em `relatorios/`.

---

## Linha do tempo (commits relevantes)

| SHA | O que entrou |
|---|---|
| `ddf7f56` | IPA **209** enviado — SheetSkin Fase 1 já presente |
| `302eeeb` | Fix coluna direita (gaps 26/16) — REGRA-MAP-CHROME-1 |
| `db391b5` | Bump `1.34.0+210` (só `pubspec.yaml`) |
| `6c0b3ae` | **SheetSkin Fase 2** — `transparent` deixa de anular fundo prata iOS |
| `681abc9` | MapBottomSheet + sheets do mapa com skin iOS |
| `8d72b7f` | Drawing tool list + header com skin iOS |
| `78d32f2` | Contraste parcial (mapa/layers/offline) — **não** cobre Relatórios |

**IPA 210 = alvo móvel:** o mesmo build number `+210` acumulou código de produto **depois** do bump. Archive às 07h45 ≠ archive às 09h40.

---

## Causa raiz 1 — inversão de contrato (produto)

**Arquivo:** `lib/core/ui/sheets/soloforte_sheet.dart`  
**Commit:** `6c0b3ae`

Fase 1 (`design/sheets.md`): `backgroundColor: Colors.transparent` era **limitação conhecida** — chrome **não** pintava prata.

Fase 2 inverteu o contrato:

```dart
// Fase 2: `Colors.transparent` não anula o fundo prata iOS
final transparentOverride =
    backgroundColor == null || backgroundColor == Colors.transparent;
resolvedBackground = transparentOverride
    ? SoloForteSheetSkinIos.background
    : backgroundColor;
```

**20+ callers** usavam `transparent` para preservar glass/conteúdo escuro. O prompt Fase 1 listava apenas **12 chamadores** e classificava risco como baixo.

### Blast radius real (`backgroundColor: Colors.transparent`)

| Bounded context | Arquivo(s) |
|---|---|
| consultoria/relatorios | `relatorios_page.dart` |
| consultoria/ocorrencias | `occurrence_creation_sheet_ui_helpers.dart`, `occurrence_detail_sheet.dart` |
| consultoria/clientes | `create_farm_sheet.dart`, `farm_map_entry_sheet.dart`, `client_detail_sub_widgets.dart`, `link_drawing_to_farm_sheet.dart` |
| marketing | `marketing_case_sheet.dart`, `marketing_photo_service.dart`, `marketing_case_reports_lookup_adapter.dart` |
| agenda | `day_event_card.dart` |
| agenda_ai | `agenda_ai_sheet.dart` |
| carteira | `carteira_screen.dart`, `carteira_cliente_screen.dart`, `categoria_form_dialog.dart` |
| planos | `planos_screen.dart` |
| map/ui | `map_sheet_controller.dart`, `visit_active_card.dart`, `publication_actions_bottom_sheet.dart` |

**Check-in tela branca (tema Azul):** `map_sheet_controller` ficou de fora do fix `9495998`.
`transparent` + chrome iOS (`Column` + handle) envolvendo `DraggableScrollableSheet`
colapsa a altura → modal prata/branco vazio. Correção: `preserveMaterialDefaults: true`
no `openSheet` (mesmo padrão dos demais hosts transparent).

### Sintoma em Relatórios

- `relatorios_page.dart` abre `OccurrenceCreationSheet` via `showSoloForteSheet(..., transparent)`.
- `relatorios_visit_photos_section.dart` usa `SoloForteSheetTokens.titleColor` (branco, skin escuro) sobre chrome agora **prata** `#F5F6F8`.
- Usuário vê sheet ilegível / “módulo quebrado” sem nenhum commit em `relatorios/`.

---

## Causa raiz 2 — processo de release (IPA alvo móvel)

- `AGENTIPA.md` registrava IPA 210 como “gerar este” **sem SHA** no momento do archive.
- Bump `db391b5` continha só chrome gaps + version bump.
- SheetSkin Fase 2 entrou **no mesmo** `+210` sem novo build number.
- **Regra:** após código de produto na `main`, próximo archive = próximo `+N`. `AGENTIPA.md` deve gravar SHA no archive.

---

## Causa raiz 3 — blast radius subestimado

- Prompt cirúrgico: 12 callers, risco baixo, zero alteração nos chamadores.
- Grep real: 8 bounded contexts, 20+ arquivos com `transparent`.
- Sem teste de contrato `transparent` / `preserveMaterialDefaults` antes do IPA 210.
- Fix de contraste (`78d32f2`) cobriu só mapa/layers/offline.

---

## Causa raiz 4 — agents dessincronizados

- `.agent/` mais novo que `prompt/AGENT_*`.
- `AGENTS.md` sem REGRA-MAP-CHROME-1 nem REGRA-SHEET-BLAST-1.
- `lib/modules/map/AGENTS.md` e `lib/modules/consultoria/AGENTS.md` sem aviso de chrome compartilhado.
- `kFabSafeArea`: 100dp em `AGENTS.md` vs 76dp em `.agent/AGENT_REGRAS.md` (corrigido para 100dp).

---

## Cautela permanente — Relatórios (pré-existente ao 210)

Não foram gatilho do IPA 210; manter em toda sessão que toque `relatorios/`:

| Tema | Referência |
|---|---|
| Logo SoloForte no header HTML | `cdce634`, `.cursor/rules/soloforte-designer.mdc` |
| `{{#if}}` fantasmas no HTML marketing | commits `5ccfa77`…`66e067c` |
| Filtro `clientId` / produtor | `f01b31a`, `bbc576a` |
| `sharePositionOrigin` iPad | `resolveSharePositionOrigin()` |
| Mutação com `agronomist_id` | `1357066` |
| Sem import direto `marketing/` | ADR-050 |

---

## REGRA-SHEET-BLAST-1 (nova — anti-regressão)

Ao tocar `lib/core/ui/sheets/` ou widgets de sheet compartilhados:

1. **Inventário obrigatório:** `rg showSoloForteSheet` + `rg 'backgroundColor: Colors.transparent'` — não confiar na lista de 12 callers de `design/sheets.md`.
2. **Proibido** inverter significado de `transparent` / `preserveMaterialDefaults` / `soloForteSheetIsIos` sem atualizar callers + teste de regressão.
3. Conteúdo com `SoloForteSheetTokens.titleColor` (branco) **não pode** assumir fundo escuro se chrome iOS for prata — usar `soloForteSheetIsIos(context)` ou `preserveMaterialDefaults: true`.
4. Mudança em `core/ui/sheets` é **transversal** (consultoria, marketing, agenda, carteira, map, drawing, planos).
5. **Proibido** reutilizar mesmo `+N` após código de produto na `main`. Próximo archive = próximo build number.
6. Coluna direita continua **REGRA-MAP-CHROME-1** — não misturar com sheet skin.

**Validação:**

```bash
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart
./tool/arch_check.sh   # REGRA-SHEET-BLAST-1
```

**Doc canônico:** `design/sheets.md` · `AGENTS.md` · `.agent/AGENT_REGRAS.md`

---

## Follow-up (fora desta blindagem)

- Correção visual dos callers quebrados (Relatórios, Marketing, Agenda, Carteira) — prompt cirúrgico separado.
- IPA **211+** com fixes visuais + novo build number.
- WIP local (flash ícones mapa, 7 arquivos) — não misturar com esta entrega.

---

## Referências

- `design/sheets.md` — contrato SheetSkin iOS
- `.agent/AGENT_REGRAS.md` — REGRA-SHEET-BLAST-1 + REGRA-MAP-CHROME-1
- `AGENTIPA.md` — histórico de builds
- `test/regression/sheets/soloforte_sheet_contract_test.dart` — gate de contrato
