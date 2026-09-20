# Avaliação de Provedores de Satélite — Cerrado

**Data:** Set/2026  
**Objetivo:** Comparar opções para frescor de imagem no bioma Cerrado sem violar ToS mobile.

## Critérios

| Critério | Peso |
|---|---|
| Frescor (≤ 12 meses no Cerrado) | Alto |
| Custo / licença mobile | Alto |
| Offline / cache permitido | Médio |
| Resolução talhão (~2 m) | Médio |
| Integração flutter_map | Médio |

## Comparativo

| Provedor | Frescor Cerrado | Licença mobile | Offline | Resolução | Notas |
|---|---|---|---|---|---|
| **MapTiler satellite-v4** | ~2020–2021 | ✅ API key | ✅ tiles XYZ | ~10 m | Base atual; refresh regional incerto |
| **Esri World Imagery** | Variável (~1–2 anos) | ⚠️ ToS ArcGIS | Parcial | ~30 cm–1 m | Requer conta ArcGIS; custo escala |
| **Mapbox Satellite** | ~1–2 anos global | ✅ Mapbox SDK/tiles | ✅ | ~30 cm | Custo por MAU; não usado hoje |
| **Planet NICFI / Basemaps** | Mensal (tropicais) | ⚠️ Contrato | Limitado | 4.77 m | Excelente frescor; custo NGO/comercial |
| **INPE WMS (BDC Cerrado)** | nov/2023 – ago/2024 | ✅ Público | ❌ WMS online | 2 m | Gratuito; só Cerrado; depende de rede |

## Recomendação

**MapTiler base + overlay INPE para Cerrado** (implementado):

1. Mantém stack atual (MapTiler + flutter_map) fora do Cerrado.
2. No bbox Cerrado, overlay `mosaic-s2-cerrado-2m` substitui visualmente a base desatualizada.
3. TTL offline 180 dias com fluxo **Atualizar área** evita cache perpetuamente velho.
4. Contato MapTiler (`MAPTILER_REFRESH_CERRADO.md`) para roadmap de refresh da base global.

## Descartados

- **Google Maps tiles:** violação ToS fora do SDK — proibido no SoloForte.
- **Planet comercial full:** custo e contrato fora do escopo v1.2; reavaliar em release futura.
- **Substituir MapTiler globalmente por Esri/Mapbox:** migração ampla sem ganho proporcional fora do Cerrado.

## Referências

- INPE BDC GeoServer: `https://data.inpe.br/bdc/geoserver/mosaics/ows`
- Layer: `mosaic-s2-cerrado-2m`
- Diagnóstico: `DIAGNOSTICO_SATELITE_CERRADO.md`
