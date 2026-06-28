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

## Qualidade obrigatoria

- Publicacao deve usar dados reais e preservar autoria/contexto.
- Regras de plano ficam explicitas e testaveis.
- Testes esperados: `test/modules/marketing/`.
- Rodar `flutter analyze lib/modules/marketing/` e `./tool/arch_check.sh`.

