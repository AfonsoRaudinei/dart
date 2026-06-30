# ADR-041 - Contrato de acesso compartilhado a ocorrencias

## Status

Ativo - 2026-06-21

## Contexto

O sync de ocorrencias pertence a `consultoria`, enquanto os vinculos aceitos
por produtores pertencem a `produtor`. Um import direto entre esses modulos
viola a fronteira arquitetural e confundia `clients.id` com identidade de
usuario.

## Decisao

`IOccurrenceAccessReader`, em `core/contracts`, expoe somente os UUIDs de
`public.clients` concedidos ao usuario autenticado por vinculos ativos. O
adapter vive em `produtor/infra` e a composicao ocorre em `lib/app`.

O contrato nao transfere ownership: `occurrences.user_id` permanece sendo o
consultor proprietario. O consumidor usa os IDs somente para leitura e cache
compartilhado, cuja identidade do receptor e armazenada separadamente.

## Consequencias

- `consultoria` nao importa `produtor`.
- Revogacao e expiracao removem o client do escopo de leitura.
- RLS continua sendo a autoridade final no backend.
