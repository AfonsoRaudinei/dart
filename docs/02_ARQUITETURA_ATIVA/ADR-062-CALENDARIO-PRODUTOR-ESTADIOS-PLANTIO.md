# ADR-062 — Calendário do produtor: estádios e plantios

**Status:** ATIVO  
**Data:** Nov/2026  
**Relacionados:** ADR-014 · ADR-038 · ADR-059 · ADR-061

## Contexto

O calendário do produtor (`/produtor/calendario`) só lista visitas
confirmadas pelo consultor (ADR-061). O catálogo da soja (VE até R8) vivia
no formulário de ocorrência. As datas de plantio, emergência e ciclo já
estão nas colunas do talhão do mapa (`drawings`), gravadas pela ocorrência
de Plantio (ADR-059). O produtor não pode importar `consultoria/` nem
`drawing/`.

## Decisão

1. O calendário do produtor ganha três segmentos na mesma tela, sem rota
   nova e sem item novo no menu: Visitas, Plantios, Estádios.
2. O catálogo `EstadioData` / `kEstadios` e a regra `suggestedEstadioForDae`
   ficam em `lib/core/domain/soy_phenology.dart`. A ocorrência importa de lá.
   O texto de cada estádio é a lista `attention` já existente. Não se
   inventa doença por estádio.
3. Contrato `IProducerCropCalendar` em `core/contracts/`. O adapter em
   `produtor/infra` lê `drawings` do usuário (`tipo = talhao`) e o nome da
   fazenda. A escrita usa `IDrawingFieldWriter.updateFieldMetadata`.
4. O produtor grava início, emergência e ciclo nos talhões da própria conta (`user_id`).
5. Colheita aproximada = emergência + `ciclo_dias`. Sem emergência,
   plantio + `ciclo_dias`. Sem ciclo, a tela diz que o ciclo não foi
   informado. Sem duração fixa de cultura.
6. Estádio de hoje = maior `dap` menor ou igual ao DAE, só para soja
   (cultura vazia conta como soja). Cultura diferente não sugere estádio.
7. Sem tabela nova e sem migration.

## Etapa seguinte (não implementada)

Uma janela de aplicação é a data de emergência somada ao `dap` do estádio
alvo. As datas e o catálogo desta decisão já sustentam esse cálculo. Sem
catálogo de produtos e sem schema extra agora.

## Não-objetivos

- Abrir a agenda do consultor para o produtor (ADR-061).
- Sugerir estádio para culturas além da soja.
- Listar doenças que não estão no catálogo atual.
