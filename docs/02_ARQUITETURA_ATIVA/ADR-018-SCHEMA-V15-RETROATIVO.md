# ADR-018 — Registro Retroativo do Schema v15 (Dívida Documental)

**Data:** 02/03/2026  
**Status:** APROVADO — retroativo (sem blocking)  
**Autor:** Engenheiro Sênior SoloForte  
**Referência PRD:** PRD_INTEGRACAO_MODULO_CLIENTES v1.1  
**Bloqueia:** Nenhum workstream  
**Baseline afetada:** ARCH_BASELINE_v1.2 — documentação pendente

---

## 1. CONTEXTO

O Schema v15 foi implementado e deployado no banco `soloforte.db` sem o correspondente ADR registrado nos documentos de arquitetura. Isso constitui **dívida documental** — o código existe e funciona, mas a decisão arquitetural não está formalizada.

Este ADR é **retroativo** — não altera código. Apenas documenta o que já existe.

---

## 2. O QUE FOI IMPLEMENTADO NO SCHEMA v15

### 2.1 Nova tabela: `client_culturas`

```sql
CREATE TABLE IF NOT EXISTS client_culturas (
  id          TEXT PRIMARY KEY,
  client_id   TEXT NOT NULL,
  cultura     TEXT NOT NULL,
  variedade   TEXT,
  area_ha     REAL,
  safra       TEXT,
  observacao  TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);
```

**Decisão:** Sub-entidade de `Client`. Relação 1:N — um cliente pode ter múltiplas culturas.  
**Cascade:** `ON DELETE CASCADE` — ao deletar cliente (soft delete via `deleted_at`), culturas são removidas.

### 2.2 Novas colunas em `clients` (V15 — 15 colunas)

| Coluna | Tipo | Nullable | Descrição |
|--------|------|----------|-----------|
| `data_nascimento` | TEXT | ✅ | Data nascimento/fundação do cliente |
| `cpf_cnpj` | TEXT | ✅ | CPF ou CNPJ |
| `area_total` | REAL | ✅ | Área total em hectares (soma das fazendas) |
| `tipo_propriedade` | TEXT | ✅ | Ex: `rural` / `urbano` / `misto` |
| `sistema_irrigacao` | TEXT | ✅ | Ex: `pivô central` / `gotejamento` / `sequeiro` |
| `solo_tipo` | TEXT | ✅ | Ex: `argiloso` / `arenoso` / `latossolo` |
| `regiao_agricola` | TEXT | ✅ | Região agrícola do Cerrado (ex: MATOPIBA) |
| `safra_atual` | TEXT | ✅ | Ex: `2025/2026` |
| `usa_assistencia_tecnica` | INTEGER | ✅ | Boolean: 0 / 1 / NULL |
| `tecnico_responsavel` | TEXT | ✅ | Nome do técnico responsável |
| `renda_estimada` | REAL | ✅ | Renda estimada anual (uso interno) |
| `credito_rural` | INTEGER | ✅ | Boolean: usa crédito rural |
| `cooperativa` | TEXT | ✅ | Nome da cooperativa associada |
| `certificacoes` | TEXT | ✅ | JSON array: ex: `["GAP","Orgânico"]` |
| `updated_at` | TEXT | ✅ | Controle de atualização (sync) |

### 2.3 Padrão de migration (idempotente)

```dart
// database_helper.dart — padrão usado em V15
for (final col in _clientV15Columns) {
  try {
    await db.execute('ALTER TABLE clients ADD COLUMN $col;');
  } catch (_) {
    // Coluna já existe — idempotente
  }
}
```

**Decisão:** Cada coluna com `try/catch` individual — se uma falhar, as demais continuam. Garante idempotência em upgrades parciais ou retroativos.

---

## 3. ENTIDADE `Client` — MAPEAMENTO DART ↔ SQLite

### Modelo Dart (após V15)

```dart
class Client {
  // Campos originais (V1+V2)
  final String id;
  final String name;
  final String? phone;
  final String? city;
  final String? state;
  final String? email;
  final String? observation;
  final String? photoPath;
  final bool active;
  final DateTime createdAt;
  final List<Farm> farms;

  // Campos V15
  final DateTime? dataNascimento;
  final String? cpfCnpj;
  final double? areaTotal;
  final String? tipoPropriedade;
  final String? sistemaIrrigacao;
  final String? soloTipo;
  final String? regiaoAgricola;
  final String? safraAtual;
  final bool? usaAssistenciaTecnica;
  final String? tecnicoResponsavel;

  // Controle
  final DateTime? updatedAt;
  final DateTime? deletedAt;  // soft delete

  // Sub-entidade
  final List<ClientCultura> culturas;  // não mapeado direto em clients — join separado
}
```

### `ClientCultura` (nova entidade)

```dart
class ClientCultura {
  final String id;
  final String clientId;
  final String cultura;
  final String? variedade;
  final double? areaHa;
  final String? safra;
  final String? observacao;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

---

## 4. BOUNDED CONTEXT

```
consultoria/clients/
├── domain/
│   ├── entities/
│   │   ├── client.dart           ← V15 campos adicionados
│   │   └── client_cultura.dart   ← NOVA entidade (V15)
│   └── agronomic_models.dart     ← modelos agronômicos (V15)
├── data/
│   ├── clients_repository.dart   ← queries incluem V15 colunas
│   └── client_cultura_repository.dart  ← NOVO repository (V15)
└── presentation/
    └── screens/
        └── client_form_screen.dart  ← campos V15 no formulário
```

**Ownership:** Todas as colunas V15 são propriedade exclusiva do bounded context `consultoria/clients/`. Zero acesso cross-module às colunas individuais (apenas via `IClientLookup` para dados públicos — ADR-015).

---

## 5. SOFT DELETE — COMPORTAMENTO EM `client_culturas`

```
Cliente soft-deleted (deleted_at NOT NULL):
  → client_culturas: CASCADE DELETE físico (aceito — culturas sem cliente são dados órfãos)
  → Justificativa: culturas não são sincronizáveis independentemente
  
Cliente com sync_status = 'pending_sync' ou 'synced':
  → NÃO usar hard delete no cliente
  → NUNCA remover cliente sem sync_status = 'local_only' ou 'deleted_local'
  → client_culturas acompanham o ciclo de vida do cliente via CASCADE
```

---

## 6. ÍNDICES CRIADOS EM V15

```sql
CREATE INDEX IF NOT EXISTS idx_client_culturas_client_id
  ON client_culturas(client_id);
```

---

## 7. CRITÉRIO DE ACEITE (RETROATIVO)

```
[x] Tabela client_culturas existe no banco (verificado)
[x] 15 colunas adicionadas em clients (verificado)
[x] Migration idempotente (try/catch por coluna)
[x] ClientCultura mapeada como entidade em domain/
[x] Client.fromMap() lê as 15 colunas V15
[x] Client.toMap() escreve as 15 colunas V15
[x] Soft delete em clients não quebra client_culturas (CASCADE)
[x] arch_check.sh passaria (sem cross-module)
```

---

## 8. NOTA SOBRE SEQUÊNCIA DE MIGRATIONS

| Versão | Conteúdo |
|--------|----------|
| V1 | Criação das tabelas base: `clients`, `farms`, `fields` |
| V2 | Índices e campos adicionais base |
| V3 | `visit_sessions` |
| V4 | `visit_reports` |
| V6, V7 | `occurrences` (extensões agronômicas) |
| V8, V9 | `drawings` + `cliente_id` em drawings |
| V10 | `agenda_events`, `agenda_visit_sessions` |
| V14 | Occurrence schema completo (ADR-014) |
| **V15** | **`client_culturas` + 15 colunas em `clients`** ← este ADR |
| V16 | `client_id` em `relatorios` (ADR-017) |

---

*SoloForte Baseline v1.2 — ADR-018 — 02/03/2026*
