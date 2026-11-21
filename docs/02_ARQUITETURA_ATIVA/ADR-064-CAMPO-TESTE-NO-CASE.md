# ADR-064 — Campo de teste vinculado ao case

**Data:** 21/11/2026  
**Status:** APROVADO  
**Módulos:** `ui/` (host do mapa), `marketing/`, `drawing/`, Supabase `marketing_cases`

## Contexto

Salvar um polígono `DrawingType.teste` grava a geometria em `drawings` e, se
houver foto, uma linha solta em `quick_photos`. A ficha Resultado | Avaliação
grava um `marketing_cases` de ponto, sem id do desenho. O contorno azul fica
no mapa e some das listas de área, porque `tipo = teste` não soma hectare.

O campo de teste é a área do Resultado e da Avaliação.

## Decisão

1. **Entrada** — o botão “Desenhar campo de teste” fica nas abas Resultado e
   Avaliação. O frasco da coluna direita e a linha Teste da grade de desenho
   saem. `selectTool('teste')` continua no controller, armado pelo host.
2. **Handoff** — `ui/` guarda o pedido (`CampoTesteCaseResume`) e, no save do
   polígono teste, reabre a mesma aba com `CampoTesteCaseSeed` (id, nome,
   hectares, cliente, fazenda, foto). `marketing/` não importa `drawing/`.
3. **Vínculo durável** — `marketing_cases.drawing_id TEXT` (nullable, sem FK:
   o desenho pode existir só no SQLite local). O cache local já persiste o
   JSON do case, então a coluna nova é só no Supabase. A ficha de leitura
   mostra “Campo de teste” quando `drawing_id` está preenchido.
4. **Geometria** — o polígono permanece em `drawings` com `tipo = teste`,
   azul Samsung, fora da soma de hectare do talhão.

## Não-objetivos

- Botão de desenhar na aba Ocorrência.
- Foto do teste deixar de ir para `quick_photos`.
- FK de `drawing_id` para `public.drawings`.
