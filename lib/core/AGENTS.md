# AGENTS.md — core

## Bounded context

`core/` e infraestrutura horizontal pura. Ele fornece contratos, database, router, network, session, feature flags, utilitarios e servicos transversais.

## Regra principal

`core/` nao conhece modulos de dominio. A unica excecao autorizada e `lib/core/router/app_router.dart`, ponto oficial de composicao de rotas.

## Permitido

- Criar ou ajustar contratos neutros em `core/contracts/`.
- Manter DTOs de fronteira sem imports de `lib/modules/`.
- Ajustar infraestrutura agnostica de dominio.
- Alterar `app_router.dart` somente com aprovacao explicita quando houver mudanca de rota.

## Proibido

- Importar `lib/modules/*` fora de `core/router/app_router.dart`.
- Colocar regra de negocio de agenda, consultoria, drawing, visitas, carteira, marketing, planos, clima ou NDVI em `core/`.
- Alterar providers compartilhados sem revisar impacto em todos os consumidores.
- Criar contrato improvisado sem ADR quando a fronteira entre modulos mudar.

## Qualidade obrigatoria

- Antes de editar: localizar arquivo e simbolo com `find`/`rg`.
- Depois de editar contratos: validar todos os consumidores e testes do modulo afetado.
- Rodar `./tool/arch_check.sh`; entrega so vale com Exit 0.

