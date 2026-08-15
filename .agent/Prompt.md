# Prompt — Travamento da coluna direita do mapa (REGRA-MAP-CHROME-1)

## Status IPA

| IPA | Inclui travamento? |
|---|---|
| **208** | ❌ NÃO — código ficou só na branch `cursor/marketing-cliente-limite-493d` (`2685139`), não mergeado em `main` |
| **209+** | ✅ Obrigatório — regenerar após merge deste fix em `main` |

## Sintoma

Ícones da coluna direita (camadas, +, check-in) se movem ao arrastar o bottom sheet ou retomar o app.

## Causa

`map_controls_overlay.dart` acoplava `Positioned.bottom` a `mapSheetChromeInsetProvider * 0.15`.

## Verdade (layout canônico)

```
bottom = kMapActionColumnBottomInset + safeBottom
       = kFabSafeArea (76) + safeBottom
```

Modo desenho: `+ kMapActionColumnDrawModeCompensation`.

## Proibido

- `mapSheetChromeInsetProvider` em `map_controls_overlay.dart`
- Offsets mágicos fora de `layout_constants.dart`

## Validação

```bash
flutter test test/regression/map/controls_overlay_regression_test.dart
./tool/arch_check.sh   # REGRA-MAP-CHROME-1 Exit 0
```

## MacBook

```bash
git pull origin main && flutter pub get
# hot restart ou IPA 209+
```
