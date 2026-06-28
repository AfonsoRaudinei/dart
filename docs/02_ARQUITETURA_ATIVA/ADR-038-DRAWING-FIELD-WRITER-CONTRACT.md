# ADR-038 — Contrato de Escrita para Talhoes do Mapa

Status: ATIVO

Data: 2026-06-07

## Contexto

As telas de detalhe de cliente e fazenda em `consultoria/clients` exibem talhoes
originados do mapa e precisam permitir exclusao desses registros. A implementacao
anterior importava `drawing/presentation/providers/drawing_provider.dart`
diretamente, criando acoplamento lateral `consultoria/ -> drawing/` bloqueado
pelo `tool/arch_check.sh`.

## Decisao

Criar o contrato neutro `IDrawingFieldWriter` em `lib/core/contracts/` para
comandos de escrita sobre talhoes originados do mapa.

O contrato e registrado via `iDrawingFieldWriterProvider`, com implementacao
concreta em `drawing/infra/drawing_field_writer_adapter.dart`.

## Regras

- `consultoria/` pode consumir apenas `iDrawingFieldWriterProvider`.
- `consultoria/` nao pode importar `drawing/` diretamente.
- `drawing/` permanece dono da escrita em `drawings`.
- A composicao concreta acontece em `main.dart`, via `ProviderScope.overrides`.

## Consequencias

- `arch_check.sh` deixa de bloquear por `consultoria/ -> drawing/`.
- A exclusao de talhao do mapa preserva o comportamento existente:
  soft delete do drawing e recalculo da area total do cliente.
- Novos comandos de escrita sobre desenhos devem ser adicionados ao contrato
  somente quando houver consumidor real fora de `drawing/`.
