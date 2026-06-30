# Matriz Oficial de Tipos de Relatório

**Status:** ATIVO  
**Data:** 03/06/2026  
**Módulos:** `consultoria/relatorios`, `consultoria/occurrences`, `marketing`, `core/html_templates`, `agenda`  
**Autoridade relacionada:** ADR-009, ADR-011, ADR-013, ADR-020

---

## 1. Objetivo

Esta matriz define os tipos oficiais de relatório suportados pelo SoloForte, a origem de dados esperada, o template HTML base, o renderer Dart responsável, o ponto de entrada de UI e os formatos de exportação obrigatórios.

Qualquer novo relatório deve ser adicionado aqui antes de virar fluxo de produto.

---

## 2. Estados de Implementação

| Estado | Significado |
|---|---|
| `Completo` | Tem origem de dados, renderer, ação UI e exportação mínima pelo `HtmlReportViewer`. |
| `Parcial` | Tem parte do pipeline implementada, mas falta ação UI oficial, exportação estruturada ou cobertura de teste. |
| `Pendente` | Template ou intenção existe, mas ainda não há fluxo funcional oficial. |

Exportação mínima atual: preview HTML + PDF por `Printing.convertHtml` + compartilhamento HTML via `HtmlReportViewer`.

Exportação estruturada obrigatória futura: `JSON` e `CSV` para os dados tabulares do relatório.

---

## 3. Matriz de Tipos

| Código | Tipo oficial | Origem de dados | Template HTML | Renderer | Entrada UI oficial | Exportação atual | Exportação obrigatória | Estado |
|---|---|---|---|---|---|---|---|---|
| `R-VISITA` | Relatório de visita | `RelatorioTecnico.toJson()` ou `AgendaVisitHtmlService.renderEventVisit()` | `assets/html_templates/relatorio_visita.html` | `VisitaHtmlRenderer.render()` | `RelatoriosScreen` e ação de visita na agenda | HTML, PDF, share HTML | JSON do relatório, CSV de ocorrências/talhões/monitoramentos | Completo |
| `R-OCORRENCIA-DETALHE` | Ocorrência detalhada | `Occurrence.toMap()` + foto base64 + JSONs agronômicos | `assets/html_templates/ocorrencia_detalhada.html` | `OcorrenciaHtmlRenderer.renderDetalhe()` | Card de ocorrência em `RelatoriosScreen` | HTML, PDF, share HTML | JSON da ocorrência, CSV de métricas/nutrientes | Completo |
| `R-OCORRENCIAS-LISTA` | Lista de ocorrências | Lista de `Occurrence`/maps por visita, cliente, fazenda ou talhão | `assets/html_templates/ocorrencias_lista.html` | `OcorrenciaHtmlRenderer.renderLista()` | Sem ação UI oficial dedicada | Renderer HTML | CSV completo de ocorrências, JSON filtrado | Parcial |
| `R-PROPRIEDADE-RESUMO` | Resumo da propriedade | Fazenda + cliente + talhões/fields | `assets/html_templates/resumo_propriedade.html` | `PropriedadeHtmlRenderer.renderPropriedade()` | Sem ação UI oficial dedicada | Renderer HTML | JSON da fazenda, CSV de talhões | Parcial |
| `R-HISTORICO-VISITAS` | Histórico de visitas | Lista de relatórios por cliente/fazenda + nomes de agrônomos | `assets/html_templates/historico_visitas.html` | `PropriedadeHtmlRenderer.renderHistorico()` | Sem ação UI oficial dedicada | Renderer HTML | JSON histórico, CSV de visitas | Parcial |
| `R-MKT-RESULTADO` | Marketing resultado | `MarketingCase.toMap()/toJson()` com `tipo = resultado` | `assets/html_templates/marketing_resultado.html` | `MarketingHtmlRenderer.render()` | Sem ação UI oficial no módulo de relatórios | Renderer HTML | JSON do case, export público/share | Parcial |
| `R-MKT-ANTES-DEPOIS` | Marketing antes/depois | `MarketingCase.toMap()/toJson()` com `tipo = antes_depois` | `assets/html_templates/marketing_antes_depois.html` | `MarketingHtmlRenderer.render()` | Sem ação UI oficial no módulo de relatórios | Renderer HTML | JSON do case, export público/share | Parcial |
| `R-MKT-AVALIACAO` | Marketing avaliação | `MarketingCase.toMap()/toJson()` com `tipo = avaliacao` + avaliações | `assets/html_templates/marketing_avaliacao.html` | `MarketingHtmlRenderer.render()` | Sem ação UI oficial no módulo de relatórios | Renderer HTML | JSON do case, JSON/CSV das avaliações | Parcial |

---

## 4. Contrato por Tipo

### R-VISITA

Responsabilidade: consolidar dados técnicos de uma visita ou evento agendado.

Campos mínimos:
- `id`
- `clientId`
- `agronomistId`
- `farmName`
- `periodStart`
- `periodEnd`
- `status`
- `talhoes`
- `ocorrencias`
- `monitoramentos`
- `fotos`
- `publicacoesRefs`

Regras:
- Deve resolver nomes reais quando houver lookup disponível: cliente, fazenda, talhão e agrônomo.
- Deve aceitar listas vazias sem vazar placeholders.
- Deve permitir exportação PDF e HTML.
- Deve permitir exportação estruturada de dados antes do fechamento 100%.

Arquivos:
- `lib/core/html_templates/visita_html_renderer.dart`
- `lib/modules/agenda/presentation/services/agenda_visit_html_service.dart`
- `lib/modules/consultoria/relatorios/presentation/relatorios_page.dart`

### R-OCORRENCIA-DETALHE

Responsabilidade: exibir uma ocorrência individual com dados agronômicos completos.

Campos mínimos:
- `id`
- `type`
- `description`
- `category`
- `status`
- `created_at`
- `updated_at`

Campos enriquecidos:
- `cultivar`
- `estadio_fenologico`
- `data_plantio`
- `amostra_solo`
- `recomendacoes`
- `metricas_json`
- `nutrientes_json`
- `notas_categorias_json`
- `fotos_categorias_json`
- `lat`
- `long`

Regras:
- JSONs agronômicos devem renderizar conteúdo real quando presentes.
- Fotos locais devem ser convertidas para data URI apenas no momento do HTML.
- Deve aceitar ausência de foto e ausência de JSON sem quebrar layout.

Arquivos:
- `lib/core/html_templates/ocorrencia_html_renderer.dart`
- `lib/modules/consultoria/occurrences/domain/occurrence.dart`
- `lib/modules/consultoria/relatorios/presentation/relatorios_page.dart`

### R-OCORRENCIAS-LISTA

Responsabilidade: consolidar múltiplas ocorrências em um relatório agrupado por categoria.

Campos mínimos:
- Lista de ocorrências com `id`, `type`, `description`, `category`, `created_at`.
- Contexto opcional: cliente, fazenda, talhão, cultivar, agrônomo, visita.

Regras:
- Deve agrupar por categoria.
- Deve calcular totais por urgência.
- Deve expor ação oficial de UI antes de ser considerado completo.
- Deve exportar CSV tabular.

Arquivos:
- `lib/core/html_templates/ocorrencia_html_renderer.dart`
- `assets/html_templates/ocorrencias_lista.html`

### R-PROPRIEDADE-RESUMO

Responsabilidade: entregar visão resumida da fazenda e seus talhões.

Campos mínimos:
- `farmId`
- `farmNome`
- `clienteNome`
- `createdAt`
- `updatedAt`
- `fields`

Regras:
- Deve calcular área produtiva a partir dos talhões.
- Deve aceitar fazendas sem talhão.
- Deve expor ação oficial no detalhe de fazenda/cliente.
- Deve exportar CSV de talhões.

Arquivos:
- `lib/core/html_templates/propriedade_html_renderer.dart`
- `assets/html_templates/resumo_propriedade.html`

### R-HISTORICO-VISITAS

Responsabilidade: listar histórico técnico de relatórios por cliente ou fazenda.

Campos mínimos:
- `clienteNome`
- Lista de relatórios com status, período, fazenda, ocorrências, talhões, fotos e publicações.

Regras:
- Deve exibir totais de visitas, publicados, pendentes e ocorrências.
- Deve aceitar lista vazia.
- Deve expor ação oficial a partir do cliente/fazenda.
- Deve exportar CSV de visitas.

Arquivos:
- `lib/core/html_templates/propriedade_html_renderer.dart`
- `assets/html_templates/historico_visitas.html`

### R-MKT-RESULTADO

Responsabilidade: demonstrar resultado técnico/comercial de produto ou manejo.

Campos mínimos:
- `tipo = resultado`
- `produtor_fazenda`
- `produto_utilizado`
- `localizacao_texto`
- `visibilidade`
- `status`

Regras:
- Deve suportar foto principal.
- Deve resolver KPIs opcionais sem renderizar seções vazias.
- Deve ter ação oficial no módulo de marketing ou relatórios antes do status completo.

Arquivos:
- `lib/core/html_templates/marketing_html_renderer.dart`
- `assets/html_templates/marketing_resultado.html`

### R-MKT-ANTES-DEPOIS

Responsabilidade: comparar cenário antes/depois com fotos e métricas.

Campos mínimos:
- `tipo = antes_depois`
- `produtor_fazenda`
- `produto_utilizado`
- `foto_antes_url`
- `foto_depois_url`
- `localizacao_texto`
- `status`

Regras:
- Deve renderizar placeholders visuais quando fotos estiverem ausentes.
- Deve exportar/share com assets resolvidos.
- Deve ter ação oficial no módulo de marketing ou relatórios antes do status completo.

Arquivos:
- `lib/core/html_templates/marketing_html_renderer.dart`
- `assets/html_templates/marketing_antes_depois.html`

### R-MKT-AVALIACAO

Responsabilidade: registrar avaliações técnicas de campo com uma ou duas fotos por avaliação.

Campos mínimos:
- `tipo = avaliacao`
- `produtor_fazenda`
- `produto_utilizado`
- `avaliacoes`

Regras:
- Deve renderizar múltiplas avaliações.
- Deve suportar layouts `duas_fotos` e foto única.
- Deve exportar avaliações como JSON/CSV.
- Deve ter ação oficial no módulo de marketing ou relatórios antes do status completo.

Arquivos:
- `lib/core/html_templates/marketing_html_renderer.dart`
- `assets/html_templates/marketing_avaliacao.html`

---

## 5. Ações Obrigatórias por Tipo

| Ação | R-VISITA | R-OCORRENCIA-DETALHE | R-OCORRENCIAS-LISTA | R-PROPRIEDADE-RESUMO | R-HISTORICO-VISITAS | Marketing |
|---|---|---|---|---|---|---|
| Pré-visualizar HTML | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório |
| Exportar PDF | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório |
| Compartilhar HTML | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório |
| Exportar JSON | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório | Obrigatório |
| Exportar CSV | Obrigatório para listas internas | Obrigatório para dados agronômicos | Obrigatório | Obrigatório | Obrigatório | Obrigatório para avaliações |
| Editar entidade origem | Obrigatório | Obrigatório | Não aplicável | Via fazenda/talhão | Não aplicável | Via marketing case |
| Excluir/arquivar | Obrigatório | Obrigatório | Não aplicável | Não aplicável | Não aplicável | Via marketing case |

---

## 6. Critério Para Declarar 100%

O módulo de relatórios só pode ser declarado 100% completo quando:

- Todos os tipos da matriz estiverem com estado `Completo`.
- Todo renderer tiver teste que garanta ausência de `{{placeholder}}` no HTML final.
- Todo tipo tiver ação UI oficial acessível por usuário.
- Todo tipo exportar PDF e HTML.
- Todo tipo exportar dados estruturados em JSON.
- Tipos com coleções exportarem CSV.
- Exportação tiver tratamento de erro visível.
- Fotos grandes tiverem limite, compressão ou estratégia documentada para evitar pressão de memória.
- Pelo menos um teste de widget validar o menu de ações do módulo de relatórios.
- Houver validação manual em iOS e Android para preview, PDF e share.

---

## 7. Próximas Pendências Diretas

1. Criar `ReportExportService` central para PDF, HTML, JSON e CSV.
2. Adicionar ação UI oficial para `R-OCORRENCIAS-LISTA`.
3. Adicionar ação UI oficial para `R-PROPRIEDADE-RESUMO`.
4. Adicionar ação UI oficial para `R-HISTORICO-VISITAS`.
5. Definir se relatórios de marketing ficam no módulo `marketing` ou aparecem também em `consultoria/relatorios`.
6. Criar testes dos renderizadores para todos os templates.
7. Criar teste de exportação estruturada.
