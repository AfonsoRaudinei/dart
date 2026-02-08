# Map Occurrence Sheet — SoloForte

## Contexto
Registro rápido de ocorrência pontual diretamente no mapa.
Este componente NÃO é relatório, NÃO é visita e NÃO é formulário agrícola completo.

## Gatilho
Ícone Ocorrências → modo armado → tap no mapa → abre sheet.

## Fonte da Verdade
- Coordenadas: capturadas no mapa (read-only)
- Persistência: SQLite local
- Pin nasce antes do sheet abrir

## Campos (mínimos)
- **Categoria** (obrigatório): Doença | Insetos | Daninhas | Nutrientes | Água
- **Urgência** (obrigatório): Baixa | Média | Alta
- **Descrição** (opcional, máx. 280 chars): Texto livre
- **Coordenadas** (read-only): lat/lng ou geometry

## Layout Visual

```
┌─────────────────────────────────────┐
│  ━━━  (drag handle)                 │
│                                     │
│  Nova Ocorrência                    │
│  ───────────────────────────────    │
│                                     │
│  Categoria                          │
│  [🦠] [🐛] [🌿] [⚗️] [💧]          │
│                                     │
│  Urgência                           │
│  ( ) Baixa  (•) Média  ( ) Alta     │
│                                     │
│  Descrição (opcional)               │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  📍 -23.550500, -46.633300          │
│                                     │
│  [Cancelar]      [Confirmar]        │
└─────────────────────────────────────┘
```

## Ações
- **Confirmar**: Salva ocorrência e fecha sheet
- **Cancelar**: Descarta e fecha sheet

## Comportamento
- Sheet abre após tap no mapa (modo armado)
- Categoria pré-selecionada: primeira opção
- Urgência pré-selecionada: Média
- Coordenadas preenchidas automaticamente
- Ao confirmar: cria ocorrência + pin no mapa
- Ao cancelar: fecha sem salvar

## Restrições
- ❌ Sem fotos
- ❌ Sem PDF
- ❌ Sem dados de visita
- ❌ Sem navegação para outras telas
- ❌ Sem lista agregada de ocorrências

## Resultado
- Ocorrência persistida localmente (SQLite)
- Pin permanente no mapa
- Sheet fecha automaticamente

## Estilo Visual (iOS-style)
- Background: branco com blur sutil
- Drag handle: cinza claro
- Categorias: chips horizontais com emoji
- Urgência: radio buttons iOS
- Botões: verde iOS (confirmar) / cinza (cancelar)
- Sombra: elevation suave
- Border radius: 16px (topo)

## Integração
- Controller: `OccurrenceController.createOccurrence()`
- Modelo: `Occurrence` com geometry GeoJSON
- Sync: automático em background
- Validação: categoria obrigatória
