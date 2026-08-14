# Prompt — SheetSkin iOS (tema Azul) · concluído em main

## Status

| Item | Valor |
|---|---|
| Feature original | commit `6230591` (branch `cursor/marketing-cliente-limite-493d`) |
| Cherry-pick em `main` | `e04e690` |
| Tag | `feat/sheet-skin-ios` |
| Restore | `restore/sheet-skin-ios-pre` (`2685139`) |
| Auditoria | LIBERADO (read-only, 14/08/2026) |

## O que foi entregue (Fase 1 — chrome)

- `SoloForteThemeExtension` + `SoloForteSheetSkinIos` em `sheet_tokens.dart`
- Registro da extension em `premium_app_theme.dart` (green / blue / black)
- `showSoloForteSheet` aplica skin iOS quando `themeId == 'blue'`
- `SoloForteSheetSkinScope` + `_SoloForteSheetChrome`
- 12 chamadores intocados

## QA device

Checklist completo em `design/sheets.md` (seção QA Versão Final).

**Critério:** chrome prata + handle azul nos sheets sem `transparent`. Marketing / visita / MapBottomSheet = limitação conhecida.

## Fase 2 (WIP local — não em main)

Conteúdo interno via `SoloForteSheetSkin.of(context)` — stash `wip-fase2-sheets-pre-cherry-pick` na branch feature.

Arquivos: `sheet_skin_resolver.dart`, widgets `sheet_card/row/actions`, `agenda_filters_sheet.dart`.

## MacBook — próximo passo

```bash
git fetch origin
git checkout main
git pull origin main
flutter pub get
git log -1 --oneline   # deve mostrar e04e690
```

Validar: Configurações → tema **Azul** → abrir sheet (avatar / agenda filtros).
