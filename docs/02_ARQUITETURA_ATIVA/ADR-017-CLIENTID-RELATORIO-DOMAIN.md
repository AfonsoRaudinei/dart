# ADR-017 — Adição de `clientId` à Entidade `Relatorio` (Contrato de Domínio)

**Data:** 02/03/2026  
**Status:** APROVADO — pré-requisito para implementação  
**Autor:** Engenheiro Sênior SoloForte  
**Referência PRD:** PRD_INTEGRACAO_MODULO_CLIENTES v1.1  
**Bloqueia:** WS-5  
**Baseline afetada:** ARCH_BASELINE_v1.2 → atualizar para v1.3 após merge

---

## 1. CONTEXTO

A entidade de domínio `Relatorio` (`lib/modules/consultoria/relatorios/domain/entities/relatorio.dart`) **não possui** o campo `clientId`, mas:

1. O model `RelatorioTecnico` (`models/relatorio_tecnico.dart`) **já possui** `clientId` — inconsistência entre domain e model
2. O Hub do Cliente (WS-4) precisa listar relatórios por cliente
3. A rota `/consultoria/relatorios?clienteId=X` (ADR-016) precisa de query capaz de filtrar por cliente

Alterar um **contrato de domínio** (entidade com `fromMap`/`toMap`/`copyWith`/`Equatable`) exige ADR pela REGRA OBRIGATÓRIA DE PROCESSO.

---

## 2. PROBLEMA

### 2.1 Inconsistência Domain ↔ Model

```dart
// ❌ ATUAL — domain/entities/relatorio.dart
class Relatorio extends Equatable {
  final String id;
  final String titulo;
  // ... demais campos
  // clientId AUSENTE
}

// ✅ ATUAL — models/relatorio_tecnico.dart
class RelatorioTecnico {
  final String? clientId;  // já existe no model
  // ...
}
```

### 2.2 Impacto de não ter `clientId` no domain

- `RelatoriosScreen` não pode filtrar por cliente
- Hub do Cliente não pode exibir contador de relatórios (query sem WHERE client_id)
- `fromMap()` ignora coluna `client_id` mesmo que ela exista no banco

---

## 3. DECISÃO

### 3.1 Adicionar `clientId` como campo nullable em `Relatorio`

```dart
// lib/modules/consultoria/relatorios/domain/entities/relatorio.dart

class Relatorio extends Equatable {
  final String id;
  final String titulo;
  // ... demais campos existentes ...
  final String? clientId;  // ← NOVO — nullable para retrocompatibilidade

  const Relatorio({
    required this.id,
    required this.titulo,
    // ...
    this.clientId,  // opcional — não quebra construtor existente
  });

  @override
  List<Object?> get props => [
    id,
    titulo,
    // ... demais props ...
    clientId,  // ← adicionar aqui
  ];

  Relatorio copyWith({
    String? id,
    String? titulo,
    // ...
    String? clientId,  // ← NOVO
    bool clearClientId = false,  // para setar null explicitamente
  }) {
    return Relatorio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      // ...
      clientId: clearClientId ? null : (clientId ?? this.clientId),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    // ...
    'client_id': clientId,  // ← NOVO — nullable, ok
  };

  factory Relatorio.fromMap(Map<String, dynamic> map) => Relatorio(
    id: map['id'] as String,
    titulo: map['titulo'] as String,
    // ...
    clientId: map['client_id'] as String?,  // ← NOVO — nullable, sem quebrar
  );
}
```

### 3.2 Migration V16 — Adicionar coluna `client_id` na tabela de relatórios

```dart
// lib/core/database/database_helper.dart
// Adicionar no método onUpgrade, case 16:

case 16:
  try {
    await db.execute(
      'ALTER TABLE relatorios ADD COLUMN client_id TEXT;',
    );
  } catch (e) {
    // Coluna pode já existir — migration idempotente
    debugPrint('ADR-017 migration V16: $e');
  }
```

**Nota:** Verificar nome exato da tabela em `database_helper.dart` antes de implementar — pode ser `relatorios` ou `visit_reports` dependendo da migration história.

### 3.3 Alinhamento com `RelatorioTecnico`

Após esta alteração, `RelatorioTecnico` (model) e `Relatorio` (domain) passam a ter `clientId` nos dois lados — inconsistência resolvida. Avaliar unificação futura (fora do escopo deste WS).

---

## 4. IMPACTO RETROATIVO

| Cenário | Comportamento |
|---------|---------------|
| Registros existentes sem `client_id` | `fromMap()` retorna `clientId = null` — sem erro |
| `toMap()` com `clientId = null` | Grava `NULL` na coluna — banco aceita (`TEXT` nullable) |
| `copyWith()` sem `clientId` | Mantém valor atual — não altera nada |
| `Equatable.props` com `clientId = null` | Funciona — `List<Object?>` aceita null |
| Filtro `WHERE client_id = ?` | Retorna apenas registros com FK real — `NULL` não aparece no filtro |

**Breaking change: NÃO.** Campo nullable com default null — nenhum código existente quebra.

---

## 5. ARQUIVOS A ALTERAR

| Arquivo | Ação |
|---------|------|
| `lib/modules/consultoria/relatorios/domain/entities/relatorio.dart` | Adicionar campo `clientId`, atualizar `fromMap`, `toMap`, `copyWith`, `props` |
| `lib/core/database/database_helper.dart` | Adicionar migration V16 |
| `lib/modules/consultoria/relatorios/data/` (repository) | Adicionar filtro `byClienteId` |
| `lib/modules/consultoria/relatorios/presentation/screens/relatorios_screen.dart` | Ler query param `clienteId` (ADR-016) |

---

## 6. CHECKLIST DE PROCESSO (REGRA OBRIGATÓRIA)

```
[x] Módulo afetado: consultoria/relatorios
[x] Altera contrato de interface: SIM → ADR-017 (este documento)
[x] Altera fronteira entre módulos: NÃO
[x] Impacto retroativo: registros antigos terão clientId = null (nullable)
[x] fromMap() atualizado
[x] toMap() atualizado
[x] copyWith() atualizado
[x] Equatable props atualizado
[x] Migration V16 adicionada (idempotente)
[x] Baseline atualizada após merge: v1.2 → v1.3
```

---

## 7. CRITÉRIO DE ACEITE

```
[ ] Campo clientId presente em Relatorio (domain) como String?
[ ] fromMap() lê client_id sem quebrar registros sem a coluna
[ ] toMap() escreve client_id (null ok)
[ ] copyWith() preserva clientId quando não informado
[ ] Equatable props inclui clientId
[ ] Migration V16 adicionada e idempotente (try/catch)
[ ] RelatoriosScreen filtra por clienteId quando query param presente
[ ] Relatórios sem clientId continuam visíveis (sem query param)
[ ] arch_check.sh passaria
```

---

## 8. ALTERNATIVAS REJEITADAS

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Adicionar apenas no Model (não no Domain) | Perpetua inconsistência; domain não reflete realidade |
| Criar entidade `RelatorioComCliente` separada | Duplicação desnecessária — `clientId` é atributo do próprio relatório |
| Filtrar via JOIN externo (sem coluna) | Acoplamento entre módulos; query mais complexa e frágil |
| Adicionar como campo não-nullable | Breaking change — todos os relatórios antigos quebrariam |

---

*SoloForte Baseline v1.2 — ADR-017 — 02/03/2026*
