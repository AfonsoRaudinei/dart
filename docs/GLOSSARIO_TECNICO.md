# Glossário Técnico - SoloForte

Este documento define os termos técnicos e conceitos de domínio utilizados no projeto SoloForte para garantir consistência entre desenvolvedores, agrônomos e stakeholders.

## Domínio Agronômico

- **Cliente**: Entidade jurídica ou física proprietária ou gestora de fazendas. No sistema, é o nível mais alto da hierarquia.
- **Fazenda (Farm)**: Propriedade rural vinculada a um Cliente. Contém múltiplos talhões.
- **Talhão (Field)**: Área de cultivo delimitada geograficamente. É a unidade básica de manejo e desenho no mapa.
- **Cultura (Crop)**: Tipo de planta cultivada no talhão (ex: Soja, Milho, Algodão).
- **Safra (Harvest)**: Período de cultivo (ex: 2024/2025).
- **Visita Técnica**: Evento de campo realizado por um consultor para coleta de dados, auditoria ou recomendação.
- **Ocorrência (Occurrence)**: Registro de evento adverso ou observação pontual no mapa (ex: Praga, Falha de Emergência, Erosão).

## Termos Técnicos (Desenho & Mapa)

- **Feature**: Representação de um objeto geográfico (ponto, linha ou polígono) seguindo o padrão GeoJSON.
- **DrawingGeometry**: A representação matemática da forma (Polygon, MultiPolygon).
- **Anel (Ring)**: Lista fechada de coordenadas que forma o limite de um polígono.
  - **Outer Ring**: Limite externo da área.
  - **Inner Ring (Hole)**: Área excluída dentro de um polígono (subtração).
- **Interaction Mode**: Estado atual da UI do mapa (ex: `idle`, `drawing`, `editing`).
- **Live Geometry**: Geometria que está sendo manipulada em tempo real pelo usuário, antes de ser persistida.

## Arquitetura & Estados

- **Map-First**: Filosofia de design onde o mapa é o centro da aplicação e a maioria das ações ocorre através ou sobre ele.
- **SmartButton**: O Float Action Button (FAB) global que muda de ícone e função conforme o contexto (Namespace).
- **Namespace**: Agrupamento lógico de rotas (ex: `dashboard`, `consultoria`, `drawing`).
- **Sync Status**: Estado de persistência de um dado em relação ao servidor.
  - `synced`: Idêntico ao servidor.
  - `pending_sync`: Alterado localmente, aguardando envio.
  - `local_only`: Criado localmente, nunca enviado.
  - `conflict`: Divergência detectada entre local e remoto.
- **SyncOrchestrator**: Serviço central que coordena a sincronização de todos os módulos.
