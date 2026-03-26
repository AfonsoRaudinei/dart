# PROMPT — NDVI Fase 1: Módulo Base + Infraestrutura
**Agente:** Engenheiro Sênior Flutter/Dart — Top 0,1%  
**Arquivo de destino:** múltiplos (ver lista na seção 4)  
**Pasta de saída:** `lib/modules/ndvi/`  
**ADR gerado:** `ADR-022-NDVI-MODULE.md`

---

## 0️⃣ PASSO 0 — AUDITORIA OBRIGATÓRIA ANTES DE QUALQUER EDIÇÃO

Execute exatamente estes comandos e reporte o resultado antes de criar qualquer arquivo:

```bash
# 1. Confirmar que o módulo ndvi NÃO existe ainda
find lib/modules/ -type d -name "ndvi"

# 2. Confirmar schema da tabela ndvi_cache no banco
grep -n "ndvi_cache" lib/core/database/database_helper.dart

# 3. Confirmar versão atual do banco soloforte.db
grep -n "currentVersion\|_dbVersion\|version.*=" lib/core/database/database_helper.dart | head -20

# 4. Confirmar que IFieldLookup NÃO existe ainda
find lib/core/contracts/ -name "i_field_lookup.dart"

# 5. Listar contratos existentes em core/contracts/
find lib/core/contracts/ -name "*.dart"

# 6. Confirmar que ndvi_fetch Edge Function está declarada
grep -rn "ndvi" lib/ --include="*.dart" | head -20
```

Se qualquer resultado for inesperado → **PARAR e reportar** antes de continuar.

---

## 1️⃣ ESCOPO

**Módulo criado:** `lib/modules/ndvi/`  
**Rotas afetadas:** nenhuma — NDVI é estado interno do mapa (`MapContext.ndvi`)  
**ADR criado:** `ADR-022-NDVI-MODULE.md`

### PROIBIDO alterar:
- Qualquer arquivo fora de `lib/modules/ndvi/` e `lib/core/contracts/`
- `app_router.dart`
- Qualquer outro módulo existente
- `arch_check.sh`
- `database_helper.dart` (apenas leitura — a migração usa o padrão existente)
- Providers globais de outros módulos

---

## 2️⃣ OBJETIVO

Criar o módulo `ndvi/` com Clean Architecture completa: entidade, repositório com interface, cache SQLite (tabela `ndvi_cache` já declarada no schema v17+), provider Riverpod e contrato `IFieldLookup` em `core/contracts/`.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não criar rota `/map/ndvi` — NDVI é `MapContext`, não rota  
❌ Não importar `ndvi/` dentro de nenhum módulo existente nesta fase  
❌ Não criar UI nesta fase (zero widgets)  
❌ Não chamar a Edge Function nesta fase (apenas contrato de repositório)  
❌ Não ultrapassar 900 linhas em nenhum arquivo novo  
❌ Não criar dados fictícios ou mock hardcoded em produção  

✅ Criar `FakeNdviRepository` apenas em `test/` para testes  
✅ Respeitar padrão `offline-first`: SQLite é fonte da verdade  
✅ Seguir padrão de nomenclatura dos outros módulos  

---

## 4️⃣ PLANEJAMENTO

### Arquivos a criar:

```
lib/modules/ndvi/
├── domain/
│   ├── entities/
│   │   └── ndvi_image.dart          ← entidade principal
│   └── repositories/
│       └── i_ndvi_repository.dart   ← contrato (interface)
├── data/
│   ├── models/
│   │   └── ndvi_image_model.dart    ← model com fromMap/toMap SQLite
│   └── repositories/
│       └── sqlite_ndvi_repository.dart ← implementação SQLite
└── presentation/
    └── providers/
        └── ndvi_providers.dart      ← providers Riverpod

lib/core/contracts/
└── i_field_lookup.dart              ← contrato DIP para busca de talhão

docs/02_ARQUITETURA_ATIVA/
└── ADR-022-NDVI-MODULE.md           ← decisão arquitetural
```

### Arquivos a criar em test/:
```
test/modules/ndvi/
├── fake_ndvi_repository.dart
└── ndvi_repository_test.dart
```

---

## 5️⃣ CONTRATO DE DADOS

### Entidade: `NdviImage`

```dart
// lib/modules/ndvi/domain/entities/ndvi_image.dart
class NdviImage {
  final String id;           // UUID v4
  final String fieldId;      // FK → talhão (drawing module)
  final DateTime imageDate;  // data da imagem de satélite
  final double ndviMin;      // valor mínimo do índice
  final double ndviMax;      // valor máximo do índice
  final double ndviMean;     // valor médio do índice
  final String? imageUrl;    // URL remota (nullable — pode ser só cache)
  final String? localPath;   // caminho local após download
  final String source;       // 'sentinel' | 'planet'
  final DateTime fetchedAt;  // quando foi buscado
  final int syncStatus;      // 0=synced | 1=pending
}
```

**Campos obrigatórios:** `id`, `fieldId`, `imageDate`, `ndviMin`, `ndviMax`, `ndviMean`, `source`, `fetchedAt`, `syncStatus`  
**Campos opcionais:** `imageUrl`, `localPath`  
**Fonte da verdade:** SQLite local (tabela `ndvi_cache`)  
**Impacto retrocompatível:** SIM — tabela nova, não altera tabelas existentes

### Interface: `INdviRepository`

```dart
abstract class INdviRepository {
  Future<List<NdviImage>> getByFieldId(String fieldId);
  Future<NdviImage?> getLatestByFieldId(String fieldId);
  Future<void> save(NdviImage image);
  Future<void> deleteByFieldId(String fieldId);
}
```

### Contrato: `IFieldLookup`

```dart
// lib/core/contracts/i_field_lookup.dart
abstract class IFieldLookup {
  Future<FieldSummary?> findById(String fieldId);
  Future<List<FieldSummary>> listByFarmId(String farmId);
}

class FieldSummary {
  final String id;
  final String name;
  final String farmId;
  final double? areaHa;
}
```

---

## 6️⃣ ESTADO

- **Tipo:** Persistente (SQLite) + Efêmero (provider em memória)  
- **AutoDispose:** SIM — `ndviImagesProvider` deve ser `autoDispose`  
- **Pode perder estado?** SIM — re-carrega do SQLite  
- **Afeta fluxo Map-First?** NÃO — módulo isolado nesta fase  

---

## 7️⃣ PERFORMANCE

- Nenhum widget criado nesta fase → zero rebuild  
- `getLatestByFieldId` deve usar `ORDER BY image_date DESC LIMIT 1`  
- Nenhum cálculo síncrono em build  
- `ndviImagesProvider(fieldId)` — family provider com `fieldId` como parâmetro  

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:** `getLatestByFieldId` retorna imagem mais recente do talhão  
**Cenário erro:** `fieldId` inexistente retorna `null` sem exception  
**Edge case:** múltiplas imagens do mesmo talhão → retorna apenas a mais recente  

**Impacta testes existentes?** NÃO  
**Testes novos:** `ndvi_repository_test.dart` com `FakeNdviRepository`  

---

## 9️⃣ MAP-FIRST CHECK

- Move raiz funcional? **NÃO**  
- Altera nível de navegação? **NÃO**  
- Cria sub-rota fora do contrato? **NÃO** — NDVI é `MapContext`, nunca rota  
- Quebra regra L0 do `/map`? **NÃO**  

---

## 🔟 RISCO

**Classificação:** Baixo  
**Motivo:** Módulo completamente novo, sem tocar código existente. Único ponto de atenção é confirmar que `ndvi_cache` já existe no schema do `database_helper.dart` antes de criar o repositório. Se a tabela não existir, **parar e reportar** — não criar migration por conta própria.

---

## 1️⃣1️⃣ EXECUÇÃO

Ordem obrigatória:

1. Criar `ADR-022-NDVI-MODULE.md`
2. Criar `IFieldLookup` em `core/contracts/`
3. Criar `NdviImage` (entidade)
4. Criar `INdviRepository` (interface)
5. Criar `NdviImageModel` (model SQLite)
6. Criar `SqliteNdviRepository` (implementação)
7. Criar `ndvi_providers.dart`
8. Criar testes com `FakeNdviRepository`

**Nada além disso.**

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

Antes de encerrar, responda:

| Pergunta | Esperado |
|---|---|
| `flutter analyze lib/modules/ndvi/` | 0 erros |
| `flutter analyze lib/core/contracts/i_field_lookup.dart` | 0 erros |
| `flutter test test/modules/ndvi/` | todos verdes |
| `./tool/arch_check.sh` | Exit 0 |
| Algum módulo existente foi alterado? | NÃO |
| Foi criada alguma rota nova? | NÃO |
| Algum arquivo novo > 900 linhas? | NÃO |

Se qualquer resposta divergir → rollback e reportar.

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

O módulo `ndvi/` (camada de domínio + dados + provider) foi criado.  
O contrato `IFieldLookup` foi adicionado a `core/contracts/`.  
O ADR-022 foi registrado.  
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
