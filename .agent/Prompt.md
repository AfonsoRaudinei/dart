# Prompt — Coluna direita do mapa (REGRA-MAP-CHROME-1)

## Status IPA

| IPA | Travamento inset | Posição canônica (imagem) |
|---|---|---|
| **208** | ❌ | ❌ `mapSheetChromeInsetProvider` |
| **209** | ✅ | ❌ spacing uniforme 12px — coluna ~26px abaixo do layout correto |
| **210+** | ✅ | ✅ gaps 26dp (camadas↔+) e 16dp (+↔check-in) |

## Verdade visual (referência imagem Porto Nacional)

Coluna fixa na direita, de cima para baixo:

1. Camadas (layers)
2. + (ações)
3. Check-in
4. SmartButton ☰ (AppShell — não mover)

```
bottom coluna = kMapActionColumnBottomInset + safeBottom  (= kFabSafeArea + safeBottom)
gap + ↔ check-in = kMapActionColumnSpacingAboveCheckIn (16)
gap camadas ↔ + = kMapActionColumnSpacingAboveActions (26)
offset camadas.bottom − check-in.bottom = 130dp
```

**Proibido:** `mapSheetChromeInsetProvider` em `map_controls_overlay.dart`.

## Validação

```bash
flutter test test/regression/map/controls_overlay_regression_test.dart
./tool/arch_check.sh
```

## MacBook

`git pull origin main` → hot restart ou IPA **210+**.
