# Regression Shield — SoloForte

Cada teste nesta pasta mapeia para um bug histórico corrigido.
Se um teste quebrar, significa que aquele bug RETORNOU.

| Arquivo | Bug | Descrição resumida |
|---------|-----|--------------------|
| auth/role_provider_regression_test.dart | BUG-001 | Role vindo de userMetadata |
| map/controls_overlay_regression_test.dart | BUG-002, BUG-005 | Botões errados na coluna direita |
| map/occurrence_sheet_regression_test.dart | BUG-003 | Sheet errado / sync_status incorreto |
| map/occurrence_creation_flow_regression_test.dart | BUG-006 | Sheet preso / perda de dados P0+P1 |
| relatorios/relatorios_screen_regression_test.dart | BUG-004 | Dados fictícios em RelatoriosScreen |

## Regra
- Nunca deletar um teste desta pasta sem ADR justificando.
- Nunca desabilitar com `skip:` sem data de expiração no comentário.
- Novo bug corrigido = novo teste aqui antes do merge.
