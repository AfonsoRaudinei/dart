# ADR 013: Submódulo de Relatórios (consultoria/relatorios)

**Status:** Aceito
**Data:** 28 de Fevereiro de 2026

## Contexto

Foi necessário criar o submódulo `relatorios/` dentro de `consultoria/` para a gestão do cadastro de relatórios com integração offline-first. As exigências incluem a criação de uma entidade alinhada ao padrão SQLite do aplicativo, implementada rigorosamente com a Clean Architecture.

## Decisão

Foi criado o submódulo interno `relatorios/` dentro do módulo `consultoria/`.
A estrutura utilizada foi a seguinte:
- **Domain:** Entidade `Relatorio` com UUID v4 e Enum de SyncStatus, além do contrato `IReportRepository`.
- **Infra:** Implementação de `ReportRepositoryImpl` fazendo uso base de Sqflite e do `DatabaseHelper` universal.
- **Application:** Providers autoDispose via Riverpod_Annotation cobrindo busca de listas completas e filtros com pesquisa interativa.
- **Presentation:** Criação da página `RelatoriosScreen` (acessível pelo namespace `/consultoria/`). O SmartButton da página utiliza o comportamento Map-First, regressando a `context.go('/map')`.

## Consequências

- Nenhuma fronteira externa de módulo foi cruzada.
- O Score 90 continua mantido de acordo com as validações de arquitetura pré-estabelecidas e garantias de isolamento.
- Arquivos de roteamento como `app_router.dart` foram refatorados sob a garantia de um substituto limpo e funcional.
