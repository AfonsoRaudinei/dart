# ADR-034: Depreciação do Módulo Legado "Reports" e exclusão da tabela visit_reports

## Status

Aceito e Implementado

## Data

2024

## Contexto

O aplicativo antigo possuía um módulo de relatórios chamado `reports/` e usava uma tabela SQLite `visit_reports` (baseada na infra herdada de "consultoria") para registrar resumos automáticos em texto da conclusão de sessões (Check-out).

Recentemente, através da ADR-025, estabelecemos um fluxo moderno com o `VisitCompletionObserver`, que cria relatórios técnicos interativos (via `GenerateRelatorioUseCase` e salvos na tabela `relatorios_v2`). Esse novo pipeline utiliza entidades ricas e fluxos neutros do Riverpod, invalidando a necessidade do registro primitivo de texto no `visit_reports`.

Havia, então, uma persistência dupla injustificada e código estático ocioso dentro do `VisitController`, acoplando o check-out com o legado.

## Decisão

Decidiu-se pela "Opção A: Limpeza Total (Deprecation)":

1. **Remoção do Acoplamento**: Retiramos do `VisitController` as injeções e invocações de persistir o relatório legado.
2. **Delete File System**: A pasta Inteira `lib/modules/consultoria/reports` foi deletada.
3. **Delete Injections**: Contratos antigos `i_visit_report_repository.dart` e implementações associadas (além da dependência em `main.dart` e em testes) removidos.
4. **Delete GUI Routes**: Remoção da tela associada e respectiva rota (`/relatorios/novo` referenciando `ReportFormScreen`) do GoRouter.
5. **Drop Database Table**: A versão do schema local subiu de 30 para 31, aplicando uma migração que executa `DROP TABLE IF EXISTS visit_reports`. O CREATE STATEMENT original em V1 foi removido do helper da aplicação.

## Consequências

**Positivas:**

* Redução de código legado sem uso real, aliviando o setup e simplificando o escopo;
* Respeito absoluto ao Single Responsibility Principle, e à ADR-025 que define `Observe` para a conclusão das visitas.
* A análise estática não gera mais avisos de injeções inatinguíveis e dependências "soltas".

**Negativas / Impactos:**

* Dados residuais armazenados antigamente na tabela local `visit_reports` sob versões primitivas foram perdidos no dispositivo do usuário, o que é esperado e desejado pois eles já eram ignorados e sobrepostos pelas métricas da nuvem e/ou pela tabela real `relatorios_v2`.

