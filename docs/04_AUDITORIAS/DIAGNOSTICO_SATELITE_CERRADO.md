# Diagnóstico — Frescor do Satélite no Cerrado

**Data:** Set/2026  
**Contexto:** SoloForte usa MapTiler `satellite-v4` como base. Usuários no Cerrado reportam defasagem de 2–4 anos em relação a referências como Google Maps.

## Pontos de referência

| Local | Coordenadas | Bioma | Uso |
|---|---|---|---|
| Sorriso/MT | -12.54, -55.72 | Cerrado agrícola | Soja/milho — alta sensibilidade a lavoura recente |
| Rio Verde/GO | -17.79, -50.93 | Cerrado agrícola | Fronteira agrícola — mudança de uso do solo |
| Dourados/MS | -22.22, -54.81 | Cerrado/ transição | Pastagem e lavoura mista |

## Sintomas observados

1. **Defasagem MapTiler:** mosaico Sentinel ~2020–2021 na camada `satellite-v4`.
2. **Amplificação offline:** cache local de 180 dias congela a imagem baixada — área desatualizada persiste mesmo online.
3. **Expectativa do usuário:** comparar com Google Earth/Maps e esperar recorte do último ano.

## Metodologia de comparação

1. Abrir SoloForte na camada Satélite (MapTiler base) nos três pontos acima.
2. Ativar **Satélite Cerrado (INPE)** no sheet Camadas (dentro do bbox Cerrado).
3. Comparar visualmente:
   - bordas de talhão,
   - áreas recém-desmatadas ou replantio,
   - estradas rurais novas.
4. Registrar data aparente da imagem (safra visível, cor da lavoura).
5. Repetir com área offline baixada — confirmar que o cache não atualiza sozinho.

## Causa raiz

| Fator | Impacto |
|---|---|
| MapTiler refresh regional | MT/GO/MS/TO não atualizados desde ~2021 |
| Cache offline 180 dias | Usuário vê imagem antiga mesmo após provedor atualizar |
| Ausência de overlay regional | Cerrado tinha só base global desatualizada |

## Mitigação implementada

- Overlay WMS INPE `mosaic-s2-cerrado-2m` (nov/2023 – ago/2024) no bioma Cerrado.
- TTL de 180 dias com UX de **Atualizar área** quando expirado.
- Banner informativo no sheet Camadas sobre defasagem MapTiler.

## Próximos passos

- Monitorar refresh MapTiler via contato comercial (ver `MAPTILER_REFRESH_CERRADO.md`).
- Avaliar provedores alternativos (`AVALIACAO_PROVEDORES_SATELITE.md`).
