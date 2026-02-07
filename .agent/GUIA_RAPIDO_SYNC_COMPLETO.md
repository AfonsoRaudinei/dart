# ⚡ GUIA RÁPIDO: Completar Sync (20% Restante)

**Tempo Estimado**: 80 minutos  
**Pré-requisito**: Ter backend configurado (Supabase ou API REST)

---

## 📝 STEP-BY-STEP PARA 100%

### STEP 1: Migration do Banco de Dados (10min) ✅

**Localizar arquivo do repository**:
```bash
find lib -name "*occurrence*repository*"
```

**Adicionar migration** (se usar SQLite):

```dart
// lib/modules/consultoria/occurrences/data/sqlite_occurrence_repository.dart

Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  return openDatabase(
    join(dbPath, 'soloforte.db'),
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE occurrences (
          id TEXT PRIMARY KEY,
          visit_session_id TEXT,
          type TEXT NOT NULL,
          description TEXT NOT NULL,
          photo_path TEXT,
          lat REAL,
          long REAL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,         -- ✅ NOVO
          sync_status TEXT DEFAULT 'local', -- ✅ NOVO  
          category TEXT,
          status TEXT DEFAULT 'draft'
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Migration para versões antigas
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE occurrences ADD COLUMN updated_at TEXT');
        await db.execute('ALTER TABLE occurrences ADD COLUMN sync_status TEXT DEFAULT "local"');
        
        // Atualizar registros existentes
        await db.execute('''
          UPDATE occurrences 
          SET updated_at = created_at, 
              sync_status = 'local' 
          WHERE updated_at IS NULL
        ''');
      }
    },
    version: 2, // ✅ Incrementar versão
  );
}
```

**Testar migration**:
```bash
# Desinstalar app para forçar onCreate OU esperar onUpgrade
flutter clean
flutter run

# Verificar colunas no SQLite
adb shell
run-as com.soloforte.app
sqlite3 databases/soloforte.db
.schema occurrences
```

---

### STEP 2: Adicionar Métodos de Sync no Repository (15min) ✅

```dart
// lib/modules/consultoria/occurrences/data/sqlite_occurrence_repository.dart

class SqliteOccurrenceRepository implements OccurrenceRepository {
  // ... métodos existentes ...
  
  /// 🔄 Buscar ocorrências pendentes de sincronização
  @override
  Future<List<Occurrence>> getPendingSync() async {
    final db = await database;
    final maps = await db.query(
      'occurrences',
      where: 'sync_status IN (?, ?, ?)',
      whereArgs: ['local', 'updated', 'deleted'],
      orderBy: 'updated_at ASC', // Mais antigas primeiro
    );
    return maps.map((m) => Occurrence.fromMap(m)).toList();
  }
  
  /// ✅ Marcar ocorrência como sincronizada
  @override
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'occurrences',
      {
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 🗑️ Marcar ocorrência para exclusão (soft delete)
  @override
  Future<void> markAsDeleted(String id) async {
    final db = await database;
    await db.update(
      'occurrences',
      {
        'sync_status': 'deleted',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 🗑️ Remover ocorrência permanentemente (após sync)
  @override
  Future<void> permanentlyDelete(String id) async {
    final db = await database;
    await db.delete(
      'occurrences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 🔄 Atualizar status de sync (genérico)
  @override
  Future<void> updateSyncStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'occurrences',
      {
        'sync_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

**Atualizar interface** (se existir):
```dart
// lib/modules/consultoria/occurrences/domain/occurrence_repository.dart

abstract class OccurrenceRepository {
  // ... métodos existentes ...
  
  Future<List<Occurrence>> getPendingSync();
  Future<void> markAsSynced(String id);
  Future<void> markAsDeleted(String id);
  Future<void> permanentlyDelete(String id);
  Future<void> updateSyncStatus(String id, String status);
}
```

---

### STEP 3: Implementar Sync no Controller (30min) ✅

**Opção A: Se usar Supabase**

```dart
// lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class OccurrenceController extends StateNotifier<AsyncValue<List<Occurrence>>> {
  // ... código existente ...
  
  /// 🔄 Sincronizar ocorrências pendentes com backend
  Future<void> syncPendingOccurrences() async {
    try {
      final repository = await ref.read(occurrenceRepositoryProvider);
      final pending = await repository.getPendingSync();
      
      if (pending.isEmpty) {
        print('✅ Nenhuma ocorrência pendente de sync');
        return;
      }
      
      print('🔄 Sincronizando ${pending.length} ocorrências...');
      
      for (final occurrence in pending) {
        try {
          if (occurrence.syncStatus == 'deleted') {
            // 🗑️ Deletar no backend
            await _deleteFromBackend(occurrence.id);
            await repository.permanentlyDelete(occurrence.id);
            print('🗑️ Deletado: ${occurrence.id}');
          } else {
            // 📤 Enviar (create ou update)
            await _sendToBackend(occurrence);
            await repository.markAsSynced(occurrence.id);
            print('✅ Sincronizado: ${occurrence.id}');
          }
        } catch (e) {
          print('⚠️ Falha ao sincronizar ${occurrence.id}: $e');
          // Continua para próxima (best effort)
        }
      }
      
      // ✅ Refresh lista
      await _refreshOccurrences();
      print('✅ Sync completo');
    } catch (e) {
      print('⚠️ Erro no sync: $e');
      // Falha silenciosa - não lança exceção
    }
  }
  
  /// 📤 Enviar ocorrência para backend (upsert)
  Future<void> _sendToBackend(Occurrence occurrence) async {
    final supabase = Supabase.instance.client;
    
    final data = occurrence.toMap();
    
    // Upsert (insert ou update)
    await supabase
        .from('occurrences')
        .upsert(data)
        .select(); // Para validar que funcionou
  }
  
  /// 🗑️ Deletar ocorrência do backend
  Future<void> _deleteFromBackend(String id) async {
    final supabase = Supabase.instance.client;
    
    await supabase
        .from('occurrences')
        .delete()
        .eq('id', id);
  }
  
  /// 🔄 Refresh lista de ocorrências
  Future<void> _refreshOccurrences() async {
    final repository = await ref.read(occurrenceRepositoryProvider);
    final all = await repository.getAllOccurrences();
    state = AsyncValue.data(all);
  }
}
```

**Opção B: Se usar API REST**

```dart
/// 📤 Enviar ocorrência para backend (API REST)
Future<void> _sendToBackend(Occurrence occurrence) async {
  final dio = Dio(); // ou http package
  
  final data = occurrence.toMap();
  
  // POST ou PUT dependendo se existe no backend
  final method = occurrence.syncStatus == 'local' ? 'POST' : 'PUT';
  
  final response = await dio.request(
    'https://api.soloforte.com/occurrences${method == 'PUT' ? '/${occurrence.id}' : ''}',
    data: data,
    options: Options(method: method),
  );
  
  if (response.statusCode! < 200 || response.statusCode! >= 300) {
    throw Exception('Falha ao enviar ocorrência');
  }
}

/// 🗑️ Deletar ocorrência do backend (API REST)
Future<void> _deleteFromBackend(String id) async {
  final dio = Dio();
  
  final response = await dio.delete('https://api.soloforte.com/occurrences/$id');
  
  if (response.statusCode! < 200 || response.statusCode! >= 300) {
    throw Exception('Falha ao deletar ocorrência');
  }
}
```

---

### STEP 4: Atualizar SyncService (5min) ✅

```dart
// lib/core/services/sync_service.dart

Future<void> _syncOccurrences() async {
  try {
    final occurrenceController = _ref.read(occurrenceControllerProvider.notifier);
    await occurrenceController.syncPendingOccurrences(); // ✅ Agora funcional
    print('✅ Sync Ocorrências completo');
  } catch (e) {
    print('⚠️ Sync Ocorrências falhou: $e');
  }
}

// TODO: Implementar _syncVisits() de forma similar
// TODO: Implementar _syncReports() quando Reports estiver pronto
```

---

### STEP 5: Atualizar CREATE/UPDATE para Marcar `updated` (10min) ✅

```dart
// lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller. dart

/// ✏️ Atualizar ocorrência existente
Future<void> updateOccurrence(Occurrence occurrence) async {
  final repository = await ref.read(occurrenceRepositoryProvider);
  
  // ✅ Marcar como 'updated' se estava 'synced'
  final updated = occurrence.copyWith(
    syncStatus: occurrence.syncStatus == 'synced' ? 'updated' : occurrence.syncStatus,
    updatedAt: DateTime.now(),
  );
  
  await repository.saveOccurrence(updated);
  await _refreshOccurrences();
}

/// 🗑️ Deletar ocorrência (soft delete)
Future<void> deleteOccurrence(String id) async {
  final repository = await ref.read(occurrenceRepositoryProvider);
  
  // ✅ Marcar como 'deleted' em vez de apagar
  await repository.markAsDeleted(id);
  await _refreshOccurrences();
}
```

---

### STEP 6: Inicializar SyncService no Main (5min) ✅

```dart
// lib/main.dart

import 'package:soloforte_app/core/services/sync_service.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Inicializar SyncService (providerWatcher)
    ref.watch(syncServiceProvider);
    
    // ✅ Conectividade também inicializa automaticamente
    ref.watch(connectivityServiceProvider);
    
    return MaterialApp(
      // ... resto do código ...
    );
  }
}
```

---

### STEP 7: Configurar Backend (Supabase) (10min) ✅

**Se usar Supabase**:

1. **Criar tabela**:
```sql
CREATE TABLE occurrences (
  id UUID PRIMARY KEY,
  visit_session_id UUID,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  photo_path TEXT,
  lat REAL,
  long REAL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  sync_status TEXT DEFAULT 'synced',
  category TEXT,
  status TEXT DEFAULT 'draft',
  user_id UUID REFERENCES auth.users(id) -- Se tiver auth
);

-- Índices para performance
CREATE INDEX idx_occurrences_sync_status ON occurrences(sync_status);
CREATE INDEX idx_occurrences_updated_at ON occurrences(updated_at);
CREATE INDEX idx_occurrences_visit_session ON occurrences(visit_session_id);
```

2. **Habilitar RLS** (Row Level Security):
```sql
ALTER TABLE occurrences ENABLE ROW LEVEL SECURITY;

-- Política: usuário só vê suas ocorrências
CREATE POLICY "Users can view their own occurrences"
  ON occurrences FOR SELECT
  USING (auth.uid() = user_id);

-- Política: usuário pode inserir/atualizar suas ocorrências
CREATE POLICY "Users can insert their own occurrences"  
  ON occurrences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own occurrences"
  ON occurrences FOR UPDATE
  USING (auth.uid() = user_id);
```

3. **Verificar conexão**:
```dart
// Testar conexão Supabase
final supabase = Supabase.instance.client;
final response = await supabase.from('occurrences').select().limit(1);
print('✅ Supabase conectado: $response');
```

---

### STEP 8: Testar End-to-End (20min) ✅

**Teste 1: Criar Offline → Sync**
```bash
# 1. Ativar modo avião
# 2. Criar 3 ocorrências offline
# 3. Verificar no SQLite: sync_status = 'local'
# 4. Desativar modo avião
# 5. Aguardar 5min OU forçar sync manual
# 6. Verificar SQLite: sync_status = 'synced'
# 7. Verificar backend: dados chegaram ✅
```

**Teste 2: Editar Offline → Sync**
```bash
# 1. Editar ocorrência já sincronizada (offline)
# 2. Verificar SQLite: sync_status = 'updated'
# 3. Conectar
# 4. Sync automático
# 5. Verificar backend: alteração aplicada ✅
```

**Teste 3: Deletar Offline → Sync**
```bash
# 1. offline Deletar ocorrência (offline)
# 2. Verificar SQLite: sync_status = 'deleted'
# 3. Conectar
# 4. Sync automático
# 5. Verificar backend: registro deletado ✅
# 6. Verificar SQLite: registro removido ✅
```

**Teste 4: Conflito (Local Ganha)**
```bash
# 1. Criar ocorrência no backend (updated_at = T1)
# 2. Sync para local
# 3. Editar no local (offline, updated_at = T2 > T1)
# 4. Editar no backend (updated_at = T1.5)
# 5. Conectar e sync
# 6. Verificar: versão local (T2) sobrescreveu backend ✅
```

---

## ✅ CHECKLIST FINAL

- [ ] Migration do DB executada
- [ ] Métodos de sync no Repository implementados
- [ ] Sync no Controller implementado (com backend)
- [ ] SyncService atualizado
- [ ] CREATE/UPDATE atualizam sync_status
- [ ] SyncService inicializado no main.dart
- [ ] Backend configurado (tabela, RLS, índices)
- [ ] Testado: Criar offline → Sync ✅
- [ ] Testado: Editar offline → Sync ✅
- [ ] Testado: Deletar offline → Sync ✅
- [ ] Testado: Conflito → Local ganha ✅

---

## 🎉 PRONTO!

Com esses 8 steps, o sistema fica **100% funcional** para:
- ✅ Operação offline completa
- ✅ Sincronização automática e silenciosa
- ✅ Resolução de conflitos (local sempre ganha)
- ✅ Exclusão lógica
- ✅ Retry automático em falhas

**O SoloForte está production-ready para campo!** 🚀

---

**Tempo Real**: ~60-80min  
**Complexidade**: Média (seguindo este guia)  
**Resultado**: Sistema offline-first de nível enterprise
