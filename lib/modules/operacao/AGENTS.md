# AGENTS.md — operacao

## Bounded context

`operacao/` representa fluxos operacionais de campo reservados para expansão futura.

**Status Fase 0 (ADR-044):** diretório **sem código Dart ativo**. Fluxos operacionais vivem em `visitas/`, `agenda/` e `ui/`. Não adicionar implementação aqui sem ADR novo.

## Contratos e dependencias

- Deve consumir outros dominios por contratos em `core/contracts/`.
- Pode ser orquestrado pelo `map/` quando houver uso espacial.

## Proibido

- Criar dominio operacional sem ADR quando isso mudar fronteiras existentes.
- Importar diretamente consultoria, drawing, agenda ou visitas sem contrato.
- Duplicar regra que ja pertence a visitas, agenda ou map.

## Qualidade obrigatoria

- Antes de adicionar codigo, documentar responsabilidade e rota de dados.
- Criar testes junto com qualquer arquivo Dart novo.
- Rodar `./tool/arch_check.sh`.

