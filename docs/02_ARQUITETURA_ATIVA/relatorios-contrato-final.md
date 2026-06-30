# Contrato final do modulo de relatorios

Data: 2026-06-03

## Tipos oficiais

| Codigo | Tipo | Renderer HTML | Estado no app |
| --- | --- | --- | --- |
| R-VISITA | Relatorio de visita | `VisitaHtmlRenderer` | Ativo na tela de relatorios |
| R-OCORRENCIA-DETALHE | Ocorrencia detalhada | `OcorrenciaHtmlRenderer.renderDetalhe` | Ativo na tela de relatorios |
| R-OCORRENCIAS-LISTA | Lista de ocorrencias | `OcorrenciaHtmlRenderer.renderLista` | Renderer validado; UI especifica pendente |
| R-PROPRIEDADE-RESUMO | Resumo da propriedade | `PropriedadeHtmlRenderer.renderPropriedade` | Renderer validado; UI especifica pendente |
| R-HISTORICO-VISITAS | Historico de visitas | `PropriedadeHtmlRenderer.renderHistorico` | Renderer validado; UI especifica pendente |
| R-MKT-RESULTADO | Marketing resultado | `MarketingHtmlRenderer` | Renderer validado; UI propria pendente |
| R-MKT-ANTES-DEPOIS | Marketing antes/depois | `MarketingHtmlRenderer` | Renderer validado; UI propria pendente |
| R-MKT-AVALIACAO | Marketing avaliacao | `MarketingHtmlRenderer` | Renderer validado; UI propria pendente |

## Formatos exportaveis

O ponto central de exportacao e `ReportExportService`.

| Formato | Contrato |
| --- | --- |
| PDF | Converte HTML via `printing` e abre fluxo nativo de PDF. |
| HTML | Gera arquivo `.html` temporario com nome seguro e compartilha. |
| JSON | Gera arquivo `.json` temporario a partir de dados estruturados. Para `RelatorioTecnico`, usa `toJson()`. |
| CSV | Gera arquivo `.csv` temporario. Para visita, inclui registros de relatorio, talhoes, ocorrencias, monitoramentos e publicacoes vinculadas. |

## Estados de relatorio

| Estado | Significado | Acoes principais |
| --- | --- | --- |
| `pendente_revisao` | Rascunho/editavel | Ver, preview HTML, exportar, editar, publicar, excluir logico |
| `publicado` | Documento aprovado | Ver, preview HTML, exportar, arquivar, excluir logico |
| `arquivado` | Fora da fila ativa | Ver, preview HTML, exportar, excluir logico |
| `deleted_local` no sync | Exclusao logica aguardando sincronizacao | Oculto da listagem ativa |

## Regras operacionais

- Widgets nao escrevem arquivos diretamente; devem chamar `ReportExportService`.
- Cards de relatorio e ocorrencia oferecem exportacao direta, alem do preview HTML.
- Falhas de exportacao aparecem visualmente via `SnackBar`.
- O menu de acoes entra em loading durante a acao para reduzir duplo clique.
- Renderers devem finalizar com HTML sem tokens `{{...}}`.
- Imagens locais grandes devem ser compactadas antes de virar base64.
