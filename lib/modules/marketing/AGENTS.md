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
- Usar cores, texto, inputs e divisores de `SoloForteSheetTokens` em `lib/core/ui/sheets/sheet_tokens.dart`.
- Não duplicar handle, título, botão de fechar ou criar dropdown/material branco fora do padrão escuro do sheet.

## Qualidade obrigatoria

- Publicacao deve usar dados reais e preservar autoria/contexto.
- Regras de plano ficam explicitas e testaveis.
- Testes esperados: `test/modules/marketing/`.
- Rodar `flutter analyze lib/modules/marketing/` e `./tool/arch_check.sh`.
