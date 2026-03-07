# ADR-014 — Occurrence Schema v14: Modelo Agronômico Completo

**Data:** 2026-03-01
**Status:** ACEITO
**Autor:** Engenheiro Sênior — módulo operacao/
**Contexto:** Feature — OccurrenceCreationSheet Agronômico Completo

---

## Contexto

O schema SQLite de `occurrences` (criado na v4) continha apenas campos básicos de
georreferenciamento e tipo. O formulário de criação (`OccurrenceCreationSheet`) era
minimalista — categoria, urgência e descrição livre.

O domínio agronômico exige um modelo enriquecido que capture:
- Cultivar e data de plantio (para cálculo de DAP)
- Estádio fenológico (17 estádios com dados de atenção agronômica)
- Múltiplas categorias por ocorrência (doença, insetos, ervas daninhas, nutrientes, água)
- Métricas por categoria (sliders de incidência, severidade, desfolha, infestação, etc.)
- Nutrientes deficientes (seleção múltipla)
- Fotos por categoria (paths locais via `image_picker`)
- Notas por categoria e observações gerais
- Tipo de ocorrência (sazonal / permanente)
- Flag de amostra de solo

---

## Decisão

### 1. Migração incremental — ALTER TABLE ADD COLUMN

Todos os 11 novos campos são **nullable** por design. A migração usa exclusivamente
`ALTER TABLE ADD COLUMN` — nunca `DROP TABLE` ou `CREATE TABLE AS SELECT`.

Isso garante:
- Registros existentes carregam sem erro (campos retornam NULL → valor default no Dart)
- Zero perda de dados históricos
- Rollback implícito: remover campos do Dart não quebra o SQLite

### 2. Versão do banco: 10 → 14

A versão salta de 10 para 14 para reservar margem para futuras migrações intermediárias
em outros módulos sem reorganização sequencial.

### 3. Campos JSON para coleções

Para evitar tabelas relacionais extras (que exigiriam JOINs e maior complexidade de
migração), os campos de coleção são armazenados como JSON TEXT:

| Campo | Tipo Dart | Exemplo |
|---|---|---|
| `metricas_json` | `Map<String, Map<String, String>>` | `{"doenca":{"incidencia":"media"}}` |
| `nutrientes_json` | `List<String>` | `["N","K","Ca"]` |
| `categorias_json` | `List<String>` | `["doenca","insetos"]` |
| `notas_categorias_json` | `Map<String, String>` | `{"doenca":"30% das folhas"}` |
| `fotos_categorias_json` | `Map<String, List<String>>` | `{"doenca":["/path/f1.jpg"]}` |

### 4. Estádios fenológicos como constante local

Os 17 estádios (`EstadioData`) são constantes em `occurrence_fenologia_data.dart`.
Não são persistidos separadamente — apenas o código do estádio selecionado é gravado
no campo `estadio_fenologico TEXT`.

### 5. `image_picker` para fotos

Fotos são capturadas via `image_picker` (já no `pubspec.yaml`).
O path local do arquivo é armazenado em `fotos_categorias_json`.
Nenhum base64 — apenas paths absolutos no filesystem do dispositivo.

---

## Schema v14 — campos novos na tabela `occurrences`

```sql
ALTER TABLE occurrences ADD COLUMN cultivar TEXT;
ALTER TABLE occurrences ADD COLUMN data_plantio TEXT;
ALTER TABLE occurrences ADD COLUMN estadio_fenologico TEXT;
ALTER TABLE occurrences ADD COLUMN tipo_ocorrencia TEXT;
ALTER TABLE occurrences ADD COLUMN amostra_solo INTEGER DEFAULT 0;
ALTER TABLE occurrences ADD COLUMN recomendacoes TEXT;
ALTER TABLE occurrences ADD COLUMN metricas_json TEXT;
ALTER TABLE occurrences ADD COLUMN nutrientes_json TEXT;
ALTER TABLE occurrences ADD COLUMN categorias_json TEXT;
ALTER TABLE occurrences ADD COLUMN notas_categorias_json TEXT;
ALTER TABLE occurrences ADD COLUMN fotos_categorias_json TEXT;
```

---

## Bounded Contexts

- `consultoria/` — **NÃO TOCA**. Consome `occurrencesListProvider` que lê de `OccurrenceRepository`.
- `marketing/` — **NÃO TOCA**.
- `operacao/` — **ÚNICO MÓDULO ALTERADO**.

O `OccurrenceRepository` é o único ponto de escrita/leitura da tabela `occurrences`.
Providers externos (`occurrencesListProvider`, `occurrenceControllerProvider`) continuam
com a mesma interface — apenas a entidade `Occurrence` é expandida.

---

## Consequências

### Positivas
- Formulário de campo completo e cientificamente válido
- Suporte a múltiplas categorias por ocorrência
- Métricas agronômicas padronizadas (sliders 0-3)
- Rastreabilidade de fotos por categoria
- Cards da lista mais informativos

### Negativas / Riscos Mitigados
- Campos JSON: não indexáveis. Mitigado: consultas usam campos escalares (`category`, `status`, etc.)
- Tamanho do registro: insignificante para SQLite mobile
- `OccurrenceController.createOccurrence()` ainda usa interface antiga: aceitável para chamadas
  de outros módulos. O novo formulário usa interface expandida diretamente via repositório.

---

## Referências

- `docs/arquitetura-ocorrencias.md`
- `docs/arquitetura-persistencia.md`
- `docs/ADR-008-RIVERPOD-NORMALIZATION.md`
- `docs/bounded_contexts.md`
