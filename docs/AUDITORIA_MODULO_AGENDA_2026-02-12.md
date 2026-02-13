# 🔍 AUDITORIA TÉCNICA - MÓDULO AGENDA
**Data**: 12 de Fevereiro de 2026  
**Revisor**: Programador Sênior Flutter/Dart  
**Escopo**: Revisão completa do módulo de Agenda (offline-first)

---

## 📊 RESUMO EXECUTIVO

### Pontuação Geral: 6.5/10

**Pontos Fortes:**
- ✅ Arquitetura limpa bem definida (domain/data/presentation)
- ✅ Offline-first implementado com SQLite
- ✅ Sync bidirecional com Supabase
- ✅ State management com Riverpod bem estruturado
- ✅ Separação de responsabilidades clara

**Pontos Críticos:**
- 🔴 **12 ERROS DE COMPILAÇÃO** impedem build
- 🔴 Dependência `equatable` faltando no pubspec.yaml
- 🔴 Arquivo corrupto: `agenda_month_page.dart`
- 🟡 Falta de tratamento de erros robusto
- 🟡 Ausência total de testes automatizados
- 🟡 SharedPreferences não implementado corretamente

---

## 🚨 PROBLEMAS CRÍTICOS (Impedem Compilação)

### 1. **Dependência Faltando - Equatable**
**Severidade**: 🔴 CRÍTICA  
**Arquivos Afetados**: `event.dart`, `visit_session.dart`

```dart
// ERRO: Target of URI doesn't exist
import 'package:equatable/equatable.dart';

class Event extends Equatable { // Classes can only extend other classes
  @override
  List<Object?> get props => [...]; // Getter doesn't override inherited
}
```

**Causa Raiz**: Package `equatable` não declarado em `pubspec.yaml`

**Impacto**: 
- Entidades não compilam
- Todo o módulo quebrado
- Impossível testar ou executar

**Solução**:
```yaml
# pubspec.yaml
dependencies:
  equatable: ^2.0.5
```

**Recomendação Adicional**: Considerar usar `@immutable` + `freezed` para DDD puro:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required EventType tipo,
    // ...
  }) = _Event;
}
```

---

### 2. **Arquivo Corrompido - agenda_month_page.dart**
**Severidade**: 🔴 CRÍTICA  
**Linha**: 29-31

```dart
// ERRO: Sintaxe inválida
@overridfilters = ref.watch(agendaFiltersProvider);
    final e  // linha cortada
  Widget build(BuildContext context) {
```

**Problema**: Merge malfeito gerou código malformado

**Impacto**: 
- Página principal não compila
- 30+ erros em cascata
- UI completamente quebrada

**Solução**: Reescrever método `build` completo (arquivo precisa ser reconstruído)

---

### 3. **API Incorreta - flutter_local_notifications**
**Severidade**: 🔴 CRÍTICA  
**Arquivos**: `agenda_notification_service.dart`

```dart
// ERRO: Too many positional arguments
await _notifications.initialize(
  settings,  // ❌ Parâmetro não existe na v17+
  onDidReceiveNotificationResponse: _onNotificationTapped,
);

// ERRO: Undefined name
uiLocalNotificationDateInterpretation:
  UILocalNotificationDateInterpretation.absoluteTime, // ❌ Removido na v16+
```

**Causa**: API mudou drasticamente entre versões

**Solução Correta** (flutter_local_notifications ^17.0.0):
```dart
final InitializationSettings initSettings = InitializationSettings(
  android: androidSettings,
  iOS: iosSettings,
);

await _notifications.initialize(
  initSettings,
  onDidReceiveNotificationResponse: _onNotificationTapped,
  onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
);

// zonedSchedule agora usa parâmetros nomeados
await _notifications.zonedSchedule(
  id,
  title,
  body,
  scheduledDate,
  notificationDetails,
  androidAllowWhileIdle: true,
  uiLocalNotificationDateInterpretation:
      DateInterpretation.absoluteTime, // ✅ Nome correto
);
```

---

### 4. **Import Faltando - GoRouter Extension**
**Severidade**: 🔴 CRÍTICA  
**Arquivo**: `day_event_card.dart` linha 85

```dart
// ERRO: The method 'push' isn't defined for BuildContext
context.push('/agenda/event/${event.id}');
```

**Causa**: Falta import da extensão do GoRouter

**Solução**:
```dart
import 'package:go_router/go_router.dart'; // ✅ Adicionar
```

---

## 🟡 PROBLEMAS GRAVES (Não Impedem Build mas Causam Bugs)

### 5. **SharedPreferences Não Implementado**
**Severidade**: 🟡 ALTA  
**Arquivo**: `agenda_filters_provider.dart` linhas 77-105

```dart
Future<void> _loadFromPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    
    if (json != null) {
      // TODO: Implement proper JSON parsing  ❌ NÃO IMPLEMENTADO
    }
  } catch (e) {
    // Ignore errors  ❌ Silencia erro crítico
  }
}

Future<void> _saveToPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // TODO: Serialize and save  ❌ NÃO IMPLEMENTADO
    await prefs.setString(_prefsKey, '{}'); // ❌ Salva vazio sempre!
  }
}
```

**Impacto**:
- Filtros não persistem entre sessões
- UX ruim (usuário perde preferências)
- Funcionalidade anunciada não funciona

**Solução**:
```dart
import 'dart:convert'; // ✅ Adicionar

Future<void> _loadFromPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    
    if (jsonString != null && jsonString.isNotEmpty) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      state = AgendaFilters.fromJson(json);
    }
  } catch (e, stack) {
    debugPrint('Erro ao carregar filtros: $e');
    debugPrintStack(stackTrace: stack);
  }
}

Future<void> _saveToPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.toJson());
    await prefs.setString(_prefsKey, jsonString);
  } catch (e, stack) {
    debugPrint('Erro ao salvar filtros: $e');
    debugPrintStack(stackTrace: stack);
  }
}
```

---

### 6. **Race Condition - Navegação em Notificações**
**Severidade**: 🟡 ALTA  
**Arquivo**: `agenda_notification_service.dart` linha 77

```dart
void _onNotificationTapped(NotificationResponse response) {
  // TODO: Navegar para o evento
  final eventId = response.payload;
  if (eventId != null) {
    // context.push('/agenda/event/$eventId');  ❌ context não disponível!
  }
}
```

**Problema**: 
- Singleton não tem acesso ao contexto
- Callback pode acontecer quando app está fechado
- Navegação vai crashar

**Solução** (Pattern: Global Navigation Key):
```dart
// 1. Criar navigation key global
// lib/core/navigation/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = 
      GlobalKey<NavigatorState>();
  
  static void navigateToEvent(String eventId) {
    navigatorKey.currentState?.pushNamed(
      '/agenda/event/$eventId',
    );
  }
}

// 2. Registrar no MaterialApp
MaterialApp.router(
  routerConfig: _router,
  navigatorKey: NavigationService.navigatorKey, // ✅
);

// 3. Usar no callback
void _onNotificationTapped(NotificationResponse response) {
  final eventId = response.payload;
  if (eventId != null) {
    NavigationService.navigateToEvent(eventId); // ✅ Funciona!
  }
}
```

---

### 7. **Falta de Transaction - Operações Atômicas**
**Severidade**: 🟡 ALTA  
**Arquivo**: `agenda_repository.dart`

```dart
Future<void> updateEvent(Event event) async {
  final db = await _dbHelper.database;
  await db.update('agenda_events', ...); // ❌ Sem transaction
}
```

**Problema**: 
- Múltiplas escritas simultâneas podem corromper dados
- Crash entre operações relacionadas deixa estado inconsistente

**Exemplo de Bug**:
```dart
// Se crashar entre essas 2 operações:
await _repository.updateEvent(event);  // ✅ Executou
await _repository.saveSession(session); // ❌ Crashou
// Resultado: event sem session, estado inválido
```

**Solução**:
```dart
Future<void> updateEventWithSession({
  required Event event,
  required VisitSession? session,
}) async {
  final db = await _dbHelper.database;
  
  await db.transaction((txn) async {
    await txn.update('agenda_events', _eventToMap(event), where: 'id = ?', whereArgs: [event.id]);
    
    if (session != null) {
      await txn.insert('agenda_visit_sessions', _sessionToMap(session), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }); // ✅ Tudo ou nada (atomic)
}
```

---

### 8. **Memory Leak - StateNotifier não Disposed**
**Severidade**: 🟡 MÉDIA  
**Arquivo**: `agenda_provider.dart`

```dart
class AgendaNotifier extends StateNotifier<AgendaState> {
  AgendaNotifier(this._repository, this._notificationService)
      : super(const AgendaState()) {
    _loadFromDatabase(); // ❌ Async sem await no constructor
    _initializeNotifications();
  }
}
```

**Problemas**:
1. Async no constructor pode causar late initialization
2. Sem `dispose()` para limpar recursos
3. Notificação service fica vivo para sempre

**Solução**:
```dart
class AgendaNotifier extends StateNotifier<AgendaState> {
  AgendaNotifier(this._repository, this._notificationService)
      : super(const AgendaState()) {
    _initialize(); // ✅ Wrapper síncrono
  }
  
  Future<void> _initialize() async {
    await _loadFromDatabase();
    await _initializeNotifications();
  }
  
  @override
  void dispose() {
    // ✅ Limpar recursos se necessário
    super.dispose();
  }
}
```

---

## 🟢 MELHORIAS RECOMENDADAS (Não Urgentes)

### 9. **Falta de Validação de Limites**
**Severidade**: 🟢 BAIXA  
**Arquivo**: `event_rules.dart`

```dart
static String? validateEventDates(DateTime dataInicio, DateTime dataFim) {
  // ...
  if (duracao.inMinutes < 5) {
    return 'Evento deve ter no mínimo 5 minutos de duração';
  }
  
  // ❌ FALTA: Validar máximo (evento de 1 ano?)
  // ❌ FALTA: Validar data no passado
  // ❌ FALTA: Validar limite de eventos por dia
  
  return null;
}
```

**Sugestão**:
```dart
static String? validateEventDates(DateTime dataInicio, DateTime dataFim) {
  final now = DateTime.now();
  
  // Validar passado (apenas warning, não erro)
  if (dataInicio.isBefore(now.subtract(const Duration(minutes: 5)))) {
    // Permitir mas avisar
  }
  
  // Validar duração mínima
  final duracao = dataFim.difference(dataInicio);
  if (duracao.inMinutes < 5) {
    return 'Evento deve ter no mínimo 5 minutos';
  }
  
  // Validar duração máxima (razoabilidade)
  if (duracao.inDays > 30) {
    return 'Evento não pode ter mais de 30 dias de duração';
  }
  
  return null;
}
```

---

### 10. **Sync Conflict Resolution Simplista**
**Severidade**: 🟢 MÉDIA  
**Arquivo**: `agenda_sync_service.dart` linha 148

```dart
// Se remoto é mais recente, atualizar
final remoteUpdatedAt = DateTime.parse(remote['updated_at']);
if (remoteUpdatedAt.isAfter(localEvent.updatedAt)) {
  await _repository.updateEvent(_mapToEvent(remote)); // ❌ Last-write-wins
}
```

**Problema**: 
- Estratégia "last-write-wins" pode perder dados
- Não considera conflitos semânticos
- Usuário não é notificado de sobrescrita

**Solução Melhorada**:
```dart
enum ConflictResolution { useLocal, useRemote, merge, askUser }

Future<void> _resolveConflict(Event local, Event remote) async {
  // Detectar tipo de conflito
  final hasStatusConflict = local.status != remote.status;
  final hasTitleConflict = local.titulo != remote.titulo;
  
  if (hasStatusConflict) {
    // Status é crítico - precisa decisão manual
    return ConflictResolution.askUser;
  }
  
  if (hasTitleConflict) {
    // Títulos diferentes - merge possível
    final merged = local.copyWith(
      titulo: '${local.titulo} / ${remote.titulo}',
    );
    await _repository.updateEvent(merged);
  }
}
```

---

### 11. **Falta de Paginação/Lazy Loading**
**Severidade**: 🟢 BAIXA  
**Arquivo**: `agenda_repository.dart` linha 58

```dart
Future<List<Event>> getAllEvents() async {
  final db = await _dbHelper.database;
  final results = await db.query(
    'agenda_events',
    orderBy: 'data_inicio_planejada ASC',
  ); // ❌ Carrega TODOS os eventos (pode ser 10.000+)
  
  return results.map(_eventFromMap).toList();
}
```

**Impacto**: 
- Performance ruim com muitos eventos
- Memória desperdiçada
- UI congela

**Solução**:
```dart
Future<List<Event>> getEventsPaginated({
  required int page,
  int pageSize = 50,
}) async {
  final db = await _dbHelper.database;
  final results = await db.query(
    'agenda_events',
    orderBy: 'data_inicio_planejada DESC',
    limit: pageSize,
    offset: page * pageSize,
  );
  
  return results.map(_eventFromMap).toList();
}

// Ou usar cursor-based pagination
Future<List<Event>> getEventsAfter(String? cursor, int limit) async {
  // WHERE id > cursor ORDER BY id LIMIT limit
}
```

---

### 12. **Recorrência Não Integrada**
**Severidade**: 🟢 MÉDIA  
**Arquivo**: `event_recurrence.dart`

```dart
class EventRecurrence {
  // ✅ Modelo criado
  // ❌ Nunca usado em Event
  // ❌ Não salva no banco
  // ❌ Dialog criado mas não integrado
}
```

**Problema**: Feature 50% implementada

**Tarefas Faltantes**:
1. Adicionar campo `recurrence` em `Event`
2. Criar coluna `recurrence_config` no SQLite (JSON)
3. Implementar geração de instâncias recorrentes
4. Ligar `RecurrenceDialog` ao `CreateEventDialog`

---

### 13. **Ausência de Testes**
**Severidade**: 🔴 CRÍTICA (longo prazo)

```
test/
└── modules/
    └── agenda/  ❌ NÃO EXISTE!
```

**Impacto**: 
- Regressões não detectadas
- Refactoring arriscado
- Baixa confiança no código

**Estrutura Sugerida**:
```
test/modules/agenda/
├── domain/
│   ├── entities/
│   │   ├── event_test.dart
│   │   └── visit_session_test.dart
│   └── rules/
│       └── event_rules_test.dart
├── data/
│   ├── repositories/
│   │   └── agenda_repository_test.dart
│   └── services/
│       └── agenda_sync_service_test.dart
└── presentation/
    └── providers/
        ├── agenda_provider_test.dart
        └── agenda_filters_provider_test.dart
```

**Exemplo de Teste Crítico**:
```dart
// test/modules/agenda/domain/rules/event_rules_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventRules.validateEventDates', () {
    test('deve rejeitar data fim antes de início', () {
      final inicio = DateTime(2026, 2, 12, 10, 0);
      final fim = DateTime(2026, 2, 12, 9, 0); // ❌ Antes!
      
      final error = EventRules.validateEventDates(inicio, fim);
      
      expect(error, isNotNull);
      expect(error, contains('posterior'));
    });
    
    test('deve aceitar evento de 1 hora', () {
      final inicio = DateTime(2026, 2, 12, 10, 0);
      final fim = DateTime(2026, 2, 12, 11, 0);
      
      final error = EventRules.validateEventDates(inicio, fim);
      
      expect(error, isNull);
    });
  });
}
```

---

### 14. **Logging Inadequado**
**Severidade**: 🟢 BAIXA  

```dart
if (kDebugMode) {
  debugPrint('✅ Agenda: Sync completo'); // ❌ Console only
}
```

**Problema**: 
- Logs só em debug
- Não persiste para análise
- Dificulta troubleshooting em produção

**Solução** (usar Logger package):
```dart
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(),
  output: MultiOutput([
    ConsoleOutput(),
    FileOutput(file: File('logs/agenda.log')), // ✅ Persiste
  ]),
);

Future<void> sync() async {
  try {
    _logger.i('Iniciando sync da agenda');
    await _pushEvents();
    _logger.d('Push events completo');
    // ...
    _logger.i('Sync completo com sucesso');
  } catch (e, stack) {
    _logger.e('Erro no sync', error: e, stackTrace: stack);
    rethrow;
  }
}
```

---

### 15. **Performance - Índices Faltando**
**Severidade**: 🟢 MÉDIA  
**Arquivo**: Queries frequentes sem índice

```sql
-- Query usada em agenda_month_page
SELECT * FROM agenda_events 
WHERE data_inicio_planejada >= ? AND data_inicio_planejada < ?
ORDER BY data_inicio_planejada ASC;

-- ❌ SEM ÍNDICE! Vai fazer table scan em 10k eventos
```

**Solução** (na migration):
```sql
-- Adicionar índices compostos
CREATE INDEX idx_agenda_events_date_range 
ON agenda_events(data_inicio_planejada, data_fim_planejada);

CREATE INDEX idx_agenda_events_cliente 
ON agenda_events(cliente_id, data_inicio_planejada);

CREATE INDEX idx_agenda_events_sync 
ON agenda_events(sync_status, updated_at);

-- Índice para filtros
CREATE INDEX idx_agenda_events_status_type 
ON agenda_events(status, tipo);
```

---

## 📋 CHECKLIST DE CORREÇÕES PRIORIZADAS

### 🔴 **FASE 1 - CRÍTICO (Impedem Build)** - 2-4 horas
- [ ] 1. Adicionar `equatable: ^2.0.5` no pubspec.yaml
- [ ] 2. Executar `flutter pub get`
- [ ] 3. Reescrever `agenda_month_page.dart` (arquivo corrompido)
- [ ] 4. Corrigir API `flutter_local_notifications` (v17 breaking changes)
- [ ] 5. Adicionar import `go_router` em `day_event_card.dart`
- [ ] 6. Testar build: `flutter build apk --debug`

### 🟡 **FASE 2 - ALTA (Bugs Graves)** - 4-6 horas
- [ ] 7. Implementar SharedPreferences completo (load/save)
- [ ] 8. Adicionar NavigationService global para notificações
- [ ] 9. Envolver operações DB em transactions
- [ ] 10. Adicionar índices no SQLite (performance)
- [ ] 11. Implementar paginação em getAllEvents()

### 🟢 **FASE 3 - MELHORIA (Qualidade)** - 8-12 horas
- [ ] 12. Completar feature de Recorrência (50% feito)
- [ ] 13. Criar suite de testes unitários (>70% coverage)
- [ ] 14. Melhorar conflict resolution no sync
- [ ] 15. Adicionar logging estruturado (Logger package)
- [ ] 16. Validações de limites (max duration, etc)

---

## 🎯 MÉTRICAS DE CÓDIGO

```
Linhas de Código: ~3.200
Arquivos: 23
Cobertura de Testes: 0% ❌
Erros de Compilação: 12 🔴
Warnings: 8 🟡
Complexidade Ciclomática Média: 8 (OK)
Dívida Técnica Estimada: 24-32 horas
```

---

## 💡 RECOMENDAÇÕES ARQUITETURAIS

### 1. **Adicionar Use Cases (Clean Architecture)**
Atualmente está pulando a camada de application:

```
❌ Atual:
Presentation -> Data (Repository)

✅ Recomendado:
Presentation -> Application (UseCases) -> Data
```

Exemplo:
```dart
// lib/modules/agenda/application/use_cases/create_event_use_case.dart
class CreateEventUseCase {
  final AgendaRepository _repository;
  final AgendaNotificationService _notificationService;
  final ConflictDetectionService _conflictService;
  
  Future<Result<Event, CreateEventFailure>> execute(CreateEventParams params) async {
    // 1. Validar
    final validation = EventRules.validateEventDates(...);
    if (validation != null) {
      return Failure(CreateEventFailure.invalidDates(validation));
    }
    
    // 2. Detectar conflitos
    final conflicts = await _conflictService.detect(params);
    if (conflicts.isNotEmpty) {
      return Failure(CreateEventFailure.conflicts(conflicts));
    }
    
    // 3. Criar
    final event = Event(...);
    await _repository.saveEvent(event);
    
    // 4. Agendar notificações
    await _notificationService.scheduleEventNotifications(event);
    
    return Success(event);
  }
}
```

### 2. **Result Type Pattern**
Evitar exceptions para controle de fluxo:

```dart
sealed class Result<S, F> {
  const Result();
}

class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

class Failure<S, F> extends Result<S, F> {
  final F error;
  const Failure(this.error);
}

// Uso:
final result = await createEventUseCase.execute(params);

result.when(
  success: (event) => showSuccess('Evento criado!'),
  failure: (error) => showError(error.message),
);
```

### 3. **Dependency Injection Container**
Usar `riverpod_annotation` ou `get_it`:

```dart
@riverpod
AgendaRepository agendaRepository(AgendaRepositoryRef ref) {
  return AgendaRepository(
    dbHelper: ref.watch(databaseHelperProvider),
  );
}

@riverpod
CreateEventUseCase createEventUseCase(CreateEventUseCaseRef ref) {
  return CreateEventUseCase(
    repository: ref.watch(agendaRepositoryProvider),
    notificationService: ref.watch(agendaNotificationServiceProvider),
  );
}
```

---

## 📚 DOCUMENTAÇÃO FALTANTE

- [ ] README.md do módulo
- [ ] Diagrama de estados (EventStatus transitions)
- [ ] Sequência de sync (Supabase)
- [ ] API docs (dartdoc)
- [ ] Guia de troubleshooting

---

## ✅ CONCLUSÃO

O módulo de Agenda tem uma **boa base arquitetural** mas sofre de:

1. **Problemas de execução** (bugs impedem uso)
2. **Falta de qualidade** (sem testes, logging ruim)
3. **Features incompletas** (recorrência, filtros não persistem)

**Estimativa para Produção**: 
- Mínimo viável: **6-8 horas** (corrigir críticos)
- Qualidade produção: **24-32 horas** (com testes e melhorias)

**Prioridade Imediata**: 
1. Corrigir erros de compilação (FASE 1)
2. Testar fluxo completo end-to-end
3. Adicionar testes críticos (create, start, complete event)

---

**Revisado por**: Programador Sênior Flutter/Dart  
**Próxima Revisão**: Após correção da FASE 1
