# AGENTS.md — dashboard

## Bounded context

`dashboard/` consolida metricas, KPIs e adaptadores de localizacao para visao operacional.

## Contratos e dependencias

- Pode consumir `core/contracts/IVisitSessionLookup`.
- Pode consumir `core/contracts/IClientLookup`.
- Nao deve virar fonte primaria de dados de outros dominios.

## Proibido

- Importar diretamente modulos de dominio para calcular KPI.
- Persistir dados derivados como se fossem fonte de verdade.
- Criar regras de negocio que pertencem a agenda, visitas ou carteira.

## Qualidade obrigatoria

- Metricas devem ser derivadas de contratos ou repositorios claros.
- Testes esperados: `test/modules/dashboard/`.
- Rodar `flutter analyze lib/modules/dashboard/` e `./tool/arch_check.sh`.

