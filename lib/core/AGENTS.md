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

## Sheets compartilhados (REGRA-SHEET-BLAST-1)

`core/ui/sheets/` e infra transversal — mudanca aqui afeta 8+ bounded contexts.

- Inventario obrigatorio: `rg showSoloForteSheet` + `rg 'backgroundColor: Colors.transparent'`
- Proibido inverter contrato `transparent` / `preserveMaterialDefaults` sem atualizar callers
- Teste: `flutter test test/regression/sheets/soloforte_sheet_contract_test.dart`
- Doc: `.agent/AUDITORIA_REGRESSAO_IPA210.md` · `design/sheets.md`

