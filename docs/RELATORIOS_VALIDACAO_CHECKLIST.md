# Checklist de Validação — Relatórios e Exportação HTML

**Escopo:** exportação share sheet, templates HTML, tela Relatórios (Flutter)  
**Branch de referência:** `cursor/fix-html-export-reports-e5c1`

---

## 1. Exportação (iOS / iPad)

| # | Cenário | Esperado | OK |
|---|---------|----------|----|
| 1.1 | Relatórios → Ocorrência → menu → **HTML** | Share sheet abre sem `sharePositionOrigin` error | ☐ |
| 1.2 | Relatórios → Visita → menu → **HTML** | Share sheet abre normalmente | ☐ |
| 1.3 | Pré-visualizar HTML → ícone share → **Exportar HTML** | Share sheet abre normalmente | ☐ |
| 1.4 | Exportar **PDF** | Diálogo de impressão/compartilhamento PDF | ☐ |
| 1.5 | Exportar **JSON/CSV** | Arquivo compartilhado sem crash | ☐ |
| 1.6 | iPad (popover) | Popover ancorado na origem do botão | ☐ |

---

## 2. Design HTML (todos os templates)

| # | Regra | Verificar | OK |
|---|-------|-----------|----|
| 2.1 | Marca SoloForte **somente no rodapé** | Header sem logo/nome SoloForte | ☐ |
| 2.2 | Rodapé **único** | Um ícone + “SoloForte” + legenda (sem bloco duplicado) | ☐ |
| 2.3 | Visão geral **sem ícones genéricos** | Cards categoria/urgência só com texto | ☐ |
| 2.4 | Localização **compacta** | Apenas ícone de pin (sem coordenadas na tela) | ☐ |
| 2.5 | Paleta **azul Samsung + petróleo** | Header petróleo; acentos Samsung | ☐ |

Templates: `relatorio_visita`, `ocorrencia_detalhada`, `ocorrencias_lista`, `resumo_propriedade`, `historico_visitas`, `marketing_antes_depois`, `marketing_avaliacao`, `marketing_resultado`.

---

## 3. UI Flutter — tela Relatórios

| # | Item | Esperado | OK |
|---|------|----------|----|
| 3.1 | Cards Ocorrências Registradas | Sem ícone warning à esquerda | ☐ |
| 3.2 | Cards Relatórios de Visita | Sem ícone documento à esquerda | ☐ |
| 3.3 | Cards consolidados / marketing | Sem ícones leading | ☐ |
| 3.4 | Erro de exportação | SnackBar legível (não PlatformException bruto) | ☐ |

---

## 4. Testes automatizados

```bash
flutter test test/core/html_templates/
flutter test test/modules/consultoria/relatorios/
flutter analyze lib/
./tool/arch_check.sh
```

| # | Suite | OK |
|---|-------|----|
| 4.1 | `report_export_service_test.dart` | ☐ |
| 4.2 | `report_renderers_placeholder_test.dart` | ☐ |
| 4.3 | `relatorios_page_actions_test.dart` | ☐ |
| 4.4 | `arch_check.sh` exit 0 | ☐ |

---

## 5. Regressão funcional

| # | Fluxo | OK |
|---|-------|----|
| 5.1 | Pré-visualizar HTML abre WebView | ☐ |
| 5.2 | Confirmar / Editar / Excluir ocorrência na lista | ☐ |
| 5.3 | Relatório de visita detalhe + publicar | ☐ |
| 5.4 | Offline: export HTML gera arquivo local | ☐ |

---

**Assinatura QA:** _______________ **Data:** _______________
