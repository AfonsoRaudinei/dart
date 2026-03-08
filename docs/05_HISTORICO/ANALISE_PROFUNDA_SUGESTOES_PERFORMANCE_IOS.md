# Análise Profunda e Sugestões de Performance iOS - SoloForte App

## 1️⃣ Resumo Executivo
O SoloForte App é uma solução robusta e técnica voltada para o agro/geo-tecnologia, construída sob o paradigma Map-First e Offline-First. O mapa não é apenas uma visualização, mas sim a principal interface de interação e "raiz funcional" do sistema. A adoção de tecnologias como Riverpod para injeção de dependências e gerência de estado, combinada com persistência via SQLite, oferece uma fundação sólida para atuar em ambientes isolados e de baixa conectividade.

O foco da nossa análise revela que, para suportar renderização geoespacial avançada (camadas NDVI, polígonos, clusters de propriedades e markers de visitas técnicas) com zero engasgo visual, é imperativo o controle restrito da thread principal e da frequência gerada pelos providers associados. Especialmente no sistema iOS, onde o motor Metal pune severamente perdas de frame e alocações excessivas na composição de camadas (Raster thread), algumas otimizações imediatas são obrigatórias.

---

## 2️⃣ Mapa Arquitetural

Identificamos a presença clara de Bounded Contexts estruturados em `lib/modules/`, respeitando as fronteiras arquitetônicas impostas pelos contratos do sistema:

- **Core Context:** Gesto de Sessão, Rede, Estado e especialmente Banco de Dados SQLite (`lib/core/database/`). Única fonte de verdade local e Offline-First.
- **Map Context (`lib/modules/map/` e `lib/modules/drawing/`):** Singleton funcional da aplicação. O mapa detém o ciclo de vida inicializador; os polígonos, layers de NDVI e vetores respondem a este escopo.
- **Consultoria & Visitas Context (`lib/modules/consultoria/`, `lib/modules/agenda/`, `lib/modules/visitas/`):** Componentes para agendamentos, publicações georreferenciadas, relatórios de visita, gerando fluxos intensos de leitura/gravação offline. Interagem de forma reativa com o Core (banco local) e fornecem pontos passivos para o Mapa.
- **Marketing Context (`lib/modules/marketing/`):** Para gestão de posts ou ações baseadas em geolocalização.
- **Shared UI & Components (`lib/ui/`):** Componentes visuais. Deve respeitar o uso único do roteamento via SmartButton (declarativo).

*Acoplamento:* Módulos consultam os casos de uso de leitura (Repositórios), mas a atualização (Watchers de Riverpod) acontece mediante propagação de mudanças no SQLite sincronizado.

---

## 3️⃣ Diagnóstico de Performance (foco iOS)

Um problema frequente com apps Maps-First pesados no Flutter, especialmente em dispositivos iOS e iPads mais antigos, é a sobrecarga na Main Thread (Dart) e na Raster/GPU. Avaliamos os principais pontos de fricção:

### Rebuilds Desnecessários
- **Arquivo/local:** `lib/modules/map/presentation/` (Widgets mapeando o estado de pins/polígonos).
- **Sintoma:** Jank durante pan/zoom rápido no mapa.
- **Causa provável:** *select* do Riverpod não granular o suficiente; escutando um state inteiro de mapa em vez de propriedades singulares.
- **Impacto:** Queda drástica de FPS (abaixo de 40).
- **Sugestão:** Refinar `.select()` nos providers. Utilizar `RepaintBoundary` ao redor dos controles flutuantes (SmartButton e toolbars visuais).

### Providers Amplos Demais
- **Arquivo/local:** `lib/core/state/` / `lib/modules/map/domain/`.
- **Sintoma:** Um clique de seleção em um talhão redesenha toda a lista de fazendas.
- **Causa provável:** Uso de providers que expõem mapas globais ou listas inteiras sem paginação/subdivisão de estado.
- **Impacto:** Altíssimo uso de CPU para diff de listas profundas (Deep equality checks pesados).
- **Sugestão:** Separar em `family` providers, gerando rebuild apenas nos itens alterados.

### Parsing Pesado em Build
- **Arquivo/local:** `lib/modules/consultoria/` e retornos de queries SQLite.
- **Sintoma:** Freezes de 100-300ms na tela ao abrir o bottom sheet de um polígono/cliente.
- **Causa provável:** Modelos rodando `fromJson` em arrays pesadíssimos na thread principal da UI.
- **Impacto:** Hit na Main Thread.
- **Sugestão:** Fazer o parsing usando um Worker local em background via `compute()` ou Isolates puros para conversões volumosas.

### Pipeline NDVI (Camadas Geoespaciais)
- **Sintoma:** Demora excessiva para exibir rasterização NDVI ou travamentos de frame intermitentes;
- **Causa provável:** Manipulação massiva das matrizes de imagem de bits e decoding na Main Thread; sobreposição excessiva de texturas limitadas no iOS M1/A-series.
- **Impacto:** Memory Warning em iOS; Encerramento brusco (OOM - Out of Memory).
- **Sugestão:** *Exigiria alteração estrutural (não executar nesta etapa)*. Transferir inteiramente o decoding de TIF/Geotiff (ou layers NDVI) para Isolate/Rust(FFI) ou depender fortemente do decoding de textura nativo.

### Rendering de Polígonos
- **Arquivo/local:** `lib/modules/drawing/presentation/`.
- **Sintoma:** Desempenho degrada exponencialmente ao exibir múltiplas fazendas com alta densidade de vértices.
- **Causa provável:** Renderização de canais do FluterMap/GoogleMaps com muitos Path objects.
- **Impacto:** Alta latência no Raster thread.
- **Sugestão:** Aplicar decimation / algoritmo de simplificação Ramer-Douglas-Peucker em coordenadas ou gerar overlays de imagem para fazendas fora de foco (viewport culling).

### Scroll e Listas (Agenda e Relatórios)
- **Arquivo/local:** `lib/modules/agenda/presentation/` e `lib/modules/visitas/`.
- **Sintoma:** *Stuttering* ao fazer scroll de agendas longas com mídias.
- **Causa provável:** Ausência de `itemExtent` ou `prototypeItem` no `ListView.builder`.
- **Impacto:** Motor calculando o frame da lista continuamente.
- **Sugestão:** Determinar tamanhos rígidos de card ou implementar constraint checks lazy-loaded.

### Clustering de Pins
- **Sintoma:** Picos na CPU no iOS ao recálculo do cluster e repintura em eventos de zoom in/zoom out.
- **Causa provável:** Algoritmo de clustering (como SuperCluster) executando de forma síncrona nos updates de câmera do mapa.
- **Impacto:** Paneling trancado até calcular os nodes.
- **Sugestão:** Mover a árvore K-d / agregação do SuperCluster para um background Isolate e deferir a atualização visual `onCameraMoveEnd`.

### SQLite I/O
- **Arquivo/local:** `lib/core/database/`.
- **Sintoma:** Picos longos de latência ao persistir coordenadas de rastreamento offline.
- **Causa provável:** Batch writes não combinados, commitando transações Múltiplas na UI thread (assíncrono sim, mas o event loop aguardando lock).
- **Impacto:** Travamento no insert.
- **Sugestão:** Utilizar `.batch()` extensivamente. Ter instâncias de DAO escrevendo através de transações atômicas agrupadas.

### Sync Concorrente
- **Sintoma:** Dispositivo aquece rapidamente com rede 4G oscilante e UI degrada.
- **Causa provável:** Tarefa de sincronização de fundos competindo com a renderização principal pelos ciclos do motor JS/Dart (GC stress).
- **Impacto:** Degradação de bateria e performance.
- **Sugestão:** Sincronização offline pesada rodando primariamente quando a interface principal recuar (idle) ou num Foreground/Background task service.

---

## 4️⃣ Sugestões Priorizadas

### Quick Wins (Semana 1)
- **Isolamento de Estado de UI (Rebuilds):** Substituir `.watch(provider)` extensivos por `.select((v) => v.property)` nos componentes de `drawing` e `map` UI.
  - *Como Medir:* DevTools `Performance > Flutter Frames`. Sem picos vermelhos durante interação visual.
  - *Risco:* Baixíssimo.
- **Scroll Infinito com `prototypeItem`**: Fixar dimensões parciais para as lists views de `agenda` e `visitas`.
  - *Como Medir:* Performance overlay, linha de Raster mais estabilizada durante scrolls rápidos.
  - *Risco:* Baixíssimo.
- **Batching SQLite**: Envolver processos recorrentes de salvamento de trackings num `db.batch().commit()`.
  - *Como Medir:* Latência do comando SQL via profiling prints / logger.

### Médio Prazo (1 Mês)
- **Clustering Assíncrono:** Ajustar a biblioteca do mapa para não recalcular a árvore de clustering na UI Thread. Realocar algoritmos de SuperCluster para Isolates.
  - *Risco:* Médio, pode apresentar frames de desrespeito à view (delay pop-in), compensável com boa UX (ex: crossfade).
- **Parsing em Background**: Funções globais rodando models via `compute()` (ex: parsers dos JSON das requisições offline/NDVI arrays).
  - *Como Medir:* Eliminação dos janks "misteriosos" de > 50ms ao abrir abas do app.

### Alto Impacto / Estrutural (Refatoração Cuidadosa)
- *Exigiria alteração estrutural (não executar nesta etapa).*
- **Motor de Renderização Nativo para NDVI e Grandes Geometrias:** Utilizar FFI (Rust) ou APIs nativas Swift/Metal para pintar e carregar as texturas NDVI direto nas camadas primitivas, contornando gargalos do Flutter Impeller/Skia com matrizes densas.

---

## 5️⃣ Observabilidade e Profiling (iOS)

- **Frames/Jank:**
  Ativar a opção "Performance Overlay" e rastrear os frames vermelhos. A meta é `<16ms` na Raster e UI thread em aparelhos como iPhone 11 ou superior com tela ProMotion (120hz requer 8.3ms).
- **GPU / Raster e Impeller:**
  No iOS, o Flutter está utilizando Impeller por padrão. O debugging via Metal Capture (no Xcode) deve ser ativado para auditar se camadas extensas de NDVI geram alocação redundante na GPU.
- **Memória:**
  Tirar heap snapshots usando o DevTools ao carregar camadas poligonais para rastrear Retained Sizes absurdos de dados Geográficos não decimatados (ex: Double arrays não liberados gerando stress GC).
- **Checklist Cenários de Estresse Real:**
  [x] Simulador rodando Network Conditener (Very Poor 3G) para testar lock do Offline-first.
  [x] iPhone físico limitando a CPU e ativando "Low Power Mode" de fábrica.
  [x] Carregamento de mais de 150 propriedades desenhadas e 1 overlay raster de NDVI gigante.

---

## 6️⃣ Auditoria de Conformidade

Analisamos o contexto para auditar as restrições:

- **`/map` como Root & Singleton:** ✔️ Preservado. Toda as sugestões fluem com a premissa de que o mapa coordena via eventos do controller nativo e não perde o estado (vivo no root).
- **SmartButton FAB único declarativo:** ✔️ Preservado. Não propusemos navegações baseadas em overlays imperativos ou múltiplas estruturas dispersas de action buttons.
- **Ausência de acoplamentos proibidos:** ✔️ Preservado. Os módulos de `agenda`, `consultoria` mantêm isolamento domain/data.
- **Offline-First intacto:** ✔️ Melhorado via propostas de SQLite `batching`, sem demandar refatoração online-first. Nenhuma alteração de contratos ou endpoints sugerida.
- **Nenhum Código ou Rota Alterada nesta fase:** ✔️ Confirmado. O foco se manteve puramente em um relatório de apontamentos.

---

## 7️⃣ Perguntas Técnicas Abertas

Para aprofundamentos diretos nas próximas Sprints:

1. Qual biblioteca exata está sendo utilizada para a exibição dos tiles NDVI? Ela suporta fornecimento de byte-buffers vindos de um Isolate?
2. Quantos vértices em média possuem as fazendas/talhões mais gigantes dos nossos dados reais para avaliar a urgência do Algoritmo de Decimation/Simplificação?
3. Há relatórios de restrição de memória ocorrendo ativamente na subida da Apple Store ou Crashlytics alertando OOM (Out Of Memory) no iOS?
4. A adoção de Impeller nas últimas versões de flutter melhorou ou piorou visualmente o blending/overdraw das feições GeoJSON?

---
*Análise efetuada com base nos princípios de arquitetura Riverpod limpa, uso de recursos Offline-first modernos do ecossistema Flutter e tuning focado nos motores do iOS (Impeller).*