# ADR-049 — Vincular Talhão do Mapa a Fazenda

Status: ATIVO

Data: 2026-08-08

## Contexto

O hub do cliente em `consultoria/clients` lista talhões originados do mapa
(`drawings`) que podem existir com `fazenda_id` nulo (órfãos). O consultor
precisa vincular esses talhões a uma fazenda existente ou criar uma fazenda
1:1 a partir do talhão, sem importar `drawing/` diretamente.

O contrato `IDrawingFieldWriter` (ADR-038) já autoriza comandos de escrita
sobre desenhos para consumidores externos, mas só expunha exclusão.

## Decisão

Estender `IDrawingFieldWriter` com:

```dart
Future<void> linkFieldToFarm({
  required String fieldId,
  required String clientId,
  required String farmId,
});
```

A implementação permanece em `drawing/infra/drawing_field_writer_adapter.dart`:
carrega o feature, atualiza `cliente_id` / `fazenda_id` / `updated_at` /
`sync_status` sem alterar geometria, e persiste via `DrawingRepository`.

## Regras

- `consultoria/` consome apenas `iDrawingFieldWriterProvider`.
- `consultoria/` não importa `drawing/`.
- `drawing/` permanece dono da escrita em `drawings`.
- Schema SQLite inalterado — apenas preenche coluna `fazenda_id` existente.
- Fazenda 1:N talhões com N≥1 é válida (incluindo fazenda = um talhão).

## Consequências

- Hub do cliente pode oferecer "Vincular à fazenda" / "Criar fazenda com este
  talhão" sem violar `arch_check`.
- Cadastro de fazenda por nome continua em `FarmRepository` / `IFarmLookup`
  (domínio consultoria); o vínculo geometrico usa este contrato.
