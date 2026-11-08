# AGENTS.md — marketing

## Bounded context

`marketing/` gerencia cases, publicacoes e regras de visibilidade vinculadas a plano.

## Contratos e dependencias

- Pode consumir `core/contracts/IClientLookup` e `IFarmLookup`.
- Pode depender de `planos/` para verificacao de plano ativo, conforme ADR.

## Proibido

- Criar dependencia nova com consultoria, drawing, agenda ou visitas sem contrato.
- Publicar case com dados inventados.
- Tratar fluxo online-only como fonte SQLite.
- Criar bottom sheet fora do padrão global.

## Padrão de bottom sheets

- Usar `showSoloForteSheet` de `lib/core/ui/sheets/soloforte_sheet.dart`.
- Cores do conteúdo (fundo, texto, inputs, chips, divisores, CTA) via `SoloForteSheetVisuals.of(context)` — resolve Verde (claro), Azul (skin iOS) e Black (escuro).
- `SoloForteSheetTokens` / `SoloForteSheetSkinIos` / `SoloForteSheetSkinLight` (`sheet_tokens.dart`) são a fonte dos valores, mas só se consomem dentro de `lib/core/ui/sheets/`; feature nova não usa token cru nem cria paleta (ver `design/sheets.md`). Proibido `isIos ? … : Colors.white`.
- Não duplicar handle, título, botão de fechar; não criar dropdown/controles Material brancos/escuros fixos que ignorem o tema.

## Qualidade obrigatoria

- Publicacao deve usar dados reais e preservar autoria/contexto.
- Regras de plano ficam explicitas e testaveis.
- Testes esperados: `test/modules/marketing/`.
- Rodar `flutter analyze lib/modules/marketing/` e `./tool/arch_check.sh`.
