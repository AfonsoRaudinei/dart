---
name: flutter-agenda-module
description: Creates a complete agenda/schedule module for Flutter apps with existing calendar integration. Features visit management, client tracking, drag & drop reordering, inline editing, efficiency metrics, and offline-first architecture. Perfect for agricultural consultants, field service teams, or any scheduling system.
license: MIT
---

# Flutter Agenda Module

A production-ready agenda module for Flutter apps that integrates seamlessly with existing calendar implementations.

**Use cases**: Agricultural consultants, field service teams, sales visit scheduling, appointment management, service dispatch systems

**Keywords**: flutter agenda, visit scheduler, calendar integration, offline-first, drag reorder, client management, field service, agricultural consulting

## Overview

This skill creates a Flutter agenda module that works alongside your existing calendar component. It manages visits, clients, and scheduling logic while your calendar handles date selection and display.

**Key Features:**
- 🗓️ Works with any calendar widget (table_calendar, syncfusion_flutter_calendar, etc.)
- 📱 Native Flutter widgets with Material Design 3
- 💾 Offline-first with Hive/SQLite persistence
- ✏️ Inline editing with long-press gesture
- 📋 Duplicate visits with single tap
- 🎯 Drag & drop reordering (ReorderableListView)
- 👥 Client management with location tracking
- 📊 Efficiency calculation with custom business rules
- 📤 PDF export via printing package

## Architecture

### Integration Model

```
Your App
├── Calendar Widget (existing)
│   └── Provides: date selection, month/week view
└── Agenda Module (this skill)
    ├── VisitListView (shows visits for selected date)
    ├── ClientManager (CRUD operations)
    ├── EfficiencyTracker (metrics calculation)
    └── DataRepository (offline persistence)
```

### File Structure

```
lib/
├── modules/
│   └── agenda/
│       ├── models/
│       │   ├── visit.dart
│       │   ├── client.dart
│       │   └── agenda_state.dart
│       ├── repositories/
│       │   ├── visit_repository.dart
│       │   └── client_repository.dart
│       ├── providers/
│       │   ├── agenda_provider.dart
│       │   └── client_provider.dart
│       ├── widgets/
│       │   ├── visit_card.dart
│       │   ├── visit_form.dart
│       │   ├── client_form.dart
│       │   ├── efficiency_badge.dart
│       │   └── inline_edit_field.dart
│       └── screens/
│           ├── agenda_screen.dart
│           └── client_list_screen.dart
└── main.dart
```

## Data Models

### Visit Model

```dart
// lib/modules/agenda/models/visit.dart
import 'package:hive/hive.dart';

part 'visit.g.dart'; // Run: flutter pub run build_runner build

@HiveType(typeId: 0)
class Visit {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime date;
  
  @HiveField(2)
  String clientName;
  
  @HiveField(3)
  String farmName;
  
  @HiveField(4)
  String location;
  
  @HiveField(5)
  String objective;
  
  @HiveField(6)
  bool completed;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  DateTime? updatedAt;
  
  Visit({
    String? id,
    required this.date,
    required this.clientName,
    required this.farmName,
    required this.location,
    required this.objective,
    this.completed = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();
  
  Visit copyWith({
    String? clientName,
    String? farmName,
    String? location,
    String? objective,
    bool? completed,
  }) {
    return Visit(
      id: id,
      date: date,
      clientName: clientName ?? this.clientName,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      objective: objective ?? this.objective,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // For duplicate functionality (new ID, uncompleted)
  Visit duplicate() {
    return Visit(
      date: date,
      clientName: clientName,
      farmName: farmName,
      location: location,
      objective: objective,
      completed: false,
    );
  }
  
  bool get isSunday => date.weekday == DateTime.sunday;
}
```

### Client Model

```dart
// lib/modules/agenda/models/client.dart
import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 1)
class Client {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String farmName;
  
  @HiveField(3)
  String? city;
  
  @HiveField(4)
  String? locationText;
  
  @HiveField(5)
  String? mapsUrl;
  
  @HiveField(6)
  double? latitude;
  
  @HiveField(7)
  double? longitude;
  
  Client({
    String? id,
    required this.name,
    required this.farmName,
    this.city,
    this.locationText,
    this.mapsUrl,
    this.latitude,
    this.longitude,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  String get displayLocation {
    if (mapsUrl != null && mapsUrl!.isNotEmpty) {
      return 'Ver no mapa';
    }
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    if (locationText != null && locationText!.isNotEmpty) {
      return locationText!;
    }
    return '—';
  }
  
  String? get mapsLink {
    if (mapsUrl != null && mapsUrl!.isNotEmpty) {
      return mapsUrl;
    }
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps?q=$latitude,$longitude';
    }
    return null;
  }
}
```

## Repository Layer

### Visit Repository (Hive)

```dart
// lib/modules/agenda/repositories/visit_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/visit.dart';

class VisitRepository {
  static const String _boxName = 'visits';
  late Box<Visit> _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VisitAdapter());
    _box = await Hive.openBox<Visit>(_boxName);
  }
  
  Future<void> addVisit(Visit visit) async {
    await _box.put(visit.id, visit);
  }
  
  Future<void> updateVisit(Visit visit) async {
    await _box.put(visit.id, visit.copyWith(updatedAt: DateTime.now()));
  }
  
  Future<void> deleteVisit(String id) async {
    await _box.delete(id);
  }
  
  List<Visit> getVisitsForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _box.values
      .where((visit) {
        final visitDate = DateTime(visit.date.year, visit.date.month, visit.date.day);
        return visitDate.isAtSameMomentAs(normalized);
      })
      .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  List<Visit> getVisitsInRange(DateTime start, DateTime end) {
    return _box.values
      .where((visit) => 
        visit.date.isAfter(start.subtract(Duration(days: 1))) &&
        visit.date.isBefore(end.add(Duration(days: 1)))
      )
      .toList();
  }
  
  Future<void> reorderVisits(List<Visit> visits) async {
    for (var visit in visits) {
      await updateVisit(visit);
    }
  }
  
  // Efficiency calculation
  double calculateEfficiency(DateTime weekStart, DateTime weekEnd) {
    final visits = getVisitsInRange(weekStart, weekEnd);
    
    int total = 0;
    int completed = 0;
    
    for (var visit in visits) {
      if (visit.isSunday) {
        // Sunday: only count if completed
        if (visit.completed) {
          total++;
          completed++;
        }
      } else {
        // Other days: always count
        total++;
        if (visit.completed) completed++;
      }
    }
    
    return total == 0 ? 0.0 : (completed / total) * 100;
  }
}
```

## Provider (State Management)

### Agenda Provider (Riverpod)

```dart
// lib/modules/agenda/providers/agenda_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visit.dart';
import '../repositories/visit_repository.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final visitsForSelectedDateProvider = Provider<List<Visit>>((ref) {
  final repository = ref.watch(visitRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return repository.getVisitsForDate(selectedDate);
});

final weeklyEfficiencyProvider = Provider<double>((ref) {
  final repository = ref.watch(visitRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  
  // Calculate week range
  final weekStart = selectedDate.subtract(
    Duration(days: selectedDate.weekday - 1)
  );
  final weekEnd = weekStart.add(Duration(days: 6));
  
  return repository.calculateEfficiency(weekStart, weekEnd);
});

class AgendaNotifier extends StateNotifier<AsyncValue<List<Visit>>> {
  final VisitRepository _repository;
  DateTime _selectedDate;
  
  AgendaNotifier(this._repository, this._selectedDate) 
    : super(const AsyncValue.loading()) {
    _loadVisits();
  }
  
  void _loadVisits() {
    state = AsyncValue.data(_repository.getVisitsForDate(_selectedDate));
  }
  
  void selectDate(DateTime date) {
    _selectedDate = date;
    _loadVisits();
  }
  
  Future<void> addVisit(Visit visit) async {
    await _repository.addVisit(visit);
    _loadVisits();
  }
  
  Future<void> updateVisit(Visit visit) async {
    await _repository.updateVisit(visit);
    _loadVisits();
  }
  
  Future<void> deleteVisit(String id) async {
    await _repository.deleteVisit(id);
    _loadVisits();
  }
  
  Future<void> duplicateVisit(Visit visit) async {
    await _repository.addVisit(visit.duplicate());
    _loadVisits();
  }
  
  Future<void> toggleCompletion(Visit visit) async {
    await _repository.updateVisit(visit.copyWith(completed: !visit.completed));
    _loadVisits();
  }
  
  Future<void> reorderVisits(int oldIndex, int newIndex) async {
    state.whenData((visits) async {
      final items = List<Visit>.from(visits);
      
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      await _repository.reorderVisits(items);
      state = AsyncValue.data(items);
    });
  }
}

final agendaProvider = StateNotifierProvider<AgendaNotifier, AsyncValue<List<Visit>>>((ref) {
  final repository = ref.watch(visitRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return AgendaNotifier(repository, selectedDate);
});
```

## UI Widgets

### Visit Card with Inline Editing

```dart
// lib/modules/agenda/widgets/visit_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/visit.dart';

class VisitCard extends StatefulWidget {
  final Visit visit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<Visit> onUpdate;
  
  const VisitCard({
    Key? key,
    required this.visit,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckChanged,
    required this.onDuplicate,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<VisitCard> {
  String? _editingField;
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _startEdit(String field, String initialValue) {
    setState(() {
      _editingField = field;
      _controllers[field] = TextEditingController(text: initialValue);
    });
  }

  void _saveEdit(String field) {
    final newValue = _controllers[field]?.text ?? '';
    if (newValue.isNotEmpty && newValue != _getFieldValue(field)) {
      Visit updatedVisit;
      
      switch (field) {
        case 'client':
          updatedVisit = widget.visit.copyWith(clientName: newValue);
          break;
        case 'farm':
          updatedVisit = widget.visit.copyWith(farmName: newValue);
          break;
        case 'location':
          updatedVisit = widget.visit.copyWith(location: newValue);
          break;
        case 'objective':
          updatedVisit = widget.visit.copyWith(objective: newValue);
          break;
        default:
          return;
      }
      
      widget.onUpdate(updatedVisit);
    }
    
    setState(() {
      _editingField = null;
      _controllers[field]?.dispose();
      _controllers.remove(field);
    });
  }

  String _getFieldValue(String field) {
    switch (field) {
      case 'client':
        return widget.visit.clientName;
      case 'farm':
        return widget.visit.farmName;
      case 'location':
        return widget.visit.location;
      case 'objective':
        return widget.visit.objective;
      default:
        return '';
    }
  }

  Widget _buildField(String field, String label, IconData icon) {
    final isEditing = _editingField == field;
    final value = _getFieldValue(field);

    return InkWell(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _startEdit(field, value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isEditing ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            isEditing
              ? TextField(
                  controller: _controllers[field],
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                  onSubmitted: (_) => _saveEdit(field),
                  onEditingComplete: () => _saveEdit(field),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: widget.visit.completed,
                    onChanged: widget.onCheckChanged,
                  ),
                  
                  // Drag handle
                  Icon(Icons.drag_handle, color: Colors.grey[400]),
                  
                  SizedBox(width: 8),
                  
                  // Fields
                  Expanded(
                    child: Column(
                      children: [
                        _buildField('client', 'Cliente', Icons.person),
                        SizedBox(height: 8),
                        _buildField('farm', 'Fazenda', Icons.agriculture),
                        SizedBox(height: 8),
                        _buildField('location', 'Localização', Icons.location_on),
                        SizedBox(height: 8),
                        _buildField('objective', 'Objetivo', Icons.flag),
                      ],
                    ),
                  ),
                  
                  // Actions
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy, size: 20),
                        onPressed: widget.onDuplicate,
                        tooltip: 'Duplicar',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: widget.onDelete,
                        tooltip: 'Excluir',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Agenda Screen (Main Interface)

```dart
// lib/modules/agenda/screens/agenda_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/agenda_provider.dart';
import '../widgets/visit_card.dart';
import '../widgets/visit_form.dart';
import '../widgets/efficiency_badge.dart';

class AgendaScreen extends ConsumerWidget {
  // Seu calendário existente passa a data selecionada via callback
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  
  const AgendaScreen({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sincronizar data selecionada
    ref.listen(selectedDateProvider, (prev, next) {
      if (next != selectedDate) {
        onDateChanged(next);
      }
    });
    
    final visitsAsync = ref.watch(agendaProvider);
    final efficiency = ref.watch(weeklyEfficiencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Visitas - ${_formatDate(selectedDate)}'),
        actions: [
          EfficiencyBadge(efficiency: efficiency),
          SizedBox(width: 16),
        ],
      ),
      body: visitsAsync.when(
        data: (visits) {
          if (visits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma visita agendada',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            itemCount: visits.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(agendaProvider.notifier).reorderVisits(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final visit = visits[index];
              
              return VisitCard(
                key: ValueKey(visit.id),
                visit: visit,
                onTap: () => _showEditDialog(context, ref, visit),
                onLongPress: () {}, // Handled by inline editing
                onCheckChanged: (value) {
                  ref.read(agendaProvider.notifier).toggleCompletion(visit);
                },
                onDuplicate: () {
                  ref.read(agendaProvider.notifier).duplicateVisit(visit);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Visita duplicada')),
                  );
                },
                onDelete: () => _confirmDelete(context, ref, visit),
                onUpdate: (updatedVisit) {
                  ref.read(agendaProvider.notifier).updateVisit(updatedVisit);
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: Icon(Icons.add),
        label: Text('Nova Visita'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return '${weekdays[date.weekday % 7]}, ${date.day}/${date.month}';
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VisitForm(
          onSave: (visit) {
            ref.read(agendaProvider.notifier).addVisit(visit);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Visit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VisitForm(
          initialVisit: visit,
          onSave: (updatedVisit) {
            ref.read(agendaProvider.notifier).updateVisit(updatedVisit);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Visit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir visita?'),
        content: Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(agendaProvider.notifier).deleteVisit(visit.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
```

## Calendar Integration

### Example with table_calendar

```dart
// In your existing calendar screen
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'modules/agenda/providers/agenda_provider.dart';
import 'modules/agenda/screens/agenda_screen.dart';

class CalendarWithAgenda extends ConsumerStatefulWidget {
  @override
  ConsumerState<CalendarWithAgenda> createState() => _CalendarWithAgendaState();
}

class _CalendarWithAgendaState extends ConsumerState<CalendarWithAgenda> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your existing calendar
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
            });
            // Update provider
            ref.read(selectedDateProvider.notifier).state = selectedDay;
          },
          // Add markers for days with visits
          eventLoader: (day) {
            final repository = ref.read(visitRepositoryProvider);
            return repository.getVisitsForDate(day);
          },
        ),
        
        Divider(),
        
        // Agenda module
        Expanded(
          child: AgendaScreen(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
      ],
    );
  }
}
```

## Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # PDF Export
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # URL Launcher (for maps)
  url_launcher: ^6.2.4
  
  # Date Formatting
  intl: ^0.18.1

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
```

## Setup Instructions

### 1. Initialize Hive

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final visitRepo = VisitRepository();
  await visitRepo.init();
  
  runApp(
    ProviderScope(
      overrides: [
        visitRepositoryProvider.overrideWithValue(visitRepo),
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Generate Hive Adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Integrate with Your Calendar

Replace your calendar's onDaySelected with provider update:
```dart
onDaySelected: (selectedDay, focusedDay) {
  ref.read(selectedDateProvider.notifier).state = selectedDay;
}
```

## Advanced Features

### PDF Export

```dart
// lib/modules/agenda/utils/pdf_exporter.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> exportWeekToPDF(List<Visit> visits, DateTime weekStart) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('Planejamento Semanal'),
        ),
        pw.SizedBox(height: 20),
        ...visits.map((visit) => pw.Container(
          margin: pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Cliente: ${visit.clientName}'),
              pw.Text('Fazenda: ${visit.farmName}'),
              pw.Text('Objetivo: ${visit.objective}'),
              pw.Divider(),
            ],
          ),
        )),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}
```

### Offline Sync

```dart
// lib/modules/agenda/services/sync_service.dart
class SyncService {
  final VisitRepository _localRepo;
  final ApiClient _apiClient;
  
  Future<void> syncVisits() async {
    try {
      // Get local changes
      final localVisits = await _localRepo.getAllVisits();
      
      // Send to server
      await _apiClient.syncVisits(localVisits);
      
      // Get server changes
      final serverVisits = await _apiClient.fetchVisits();
      
      // Merge (last-write-wins or custom logic)
      await _localRepo.bulkUpdate(serverVisits);
    } catch (e) {
      // Handle offline - queue for later
    }
  }
}
```

## Testing

```dart
// test/modules/agenda/visit_repository_test.dart
void main() {
  late VisitRepository repository;
  
  setUp(() async {
    await Hive.initFlutter();
    Hive.init(Directory.systemTemp.path);
    repository = VisitRepository();
    await repository.init();
  });
  
  tearDown(() async {
    await Hive.deleteFromDisk();
  });
  
  test('should add and retrieve visit', () async {
    final visit = Visit(
      date: DateTime(2026, 2, 18),
      clientName: 'Test Client',
      farmName: 'Test Farm',
      location: 'Test Location',
      objective: 'Test Objective',
    );
    
    await repository.addVisit(visit);
    
    final visits = repository.getVisitsForDate(DateTime(2026, 2, 18));
    expect(visits.length, 1);
    expect(visits.first.clientName, 'Test Client');
  });
  
  test('should calculate efficiency correctly', () async {
    // Add test visits...
    final efficiency = repository.calculateEfficiency(
      DateTime(2026, 2, 17),
      DateTime(2026, 2, 23),
    );
    
    expect(efficiency, 50.0); // Assuming 2 visits, 1 completed
  });
}
```

## Best Practices

### 1. Offline-First
- All data saved locally first
- Sync in background
- Queue failed sync attempts

### 2. Performance
- Use Hive indexes for fast queries
- Lazy load visit details
- Paginate long lists

### 3. UX
- HapticFeedback on interactions
- Optimistic UI updates
- Clear error messages

### 4. Data Integrity
- Validate before save
- Handle concurrent edits
- Backup before major operations

## Troubleshooting

**Hive box not opening:**
```dart
// Ensure Hive.init() called before openBox()
await Hive.initFlutter();
```

**Drag reorder not working:**
```dart
// Ensure unique keys
key: ValueKey(visit.id)
```

**Inline editing not saving:**
```dart
// Check onUpdate callback is wired correctly
onUpdate: (visit) => ref.read(agendaProvider.notifier).updateVisit(visit)
```

---

**Version**: 1.0.0  
**Platform**: Flutter 3.16+, Dart 3.2+  
**License**: MIT

- 📅 **Day-based organization** with expandable cards
- 👥 **Client management** with location tracking (Google Maps integration)
- ✏️ **Inline editing** (double-click any field)
- 📋 **Duplicate visits** for recurring appointments
- 🎯 **Drag & drop** to reorder or move between days
- 📊 **Efficiency tracking** with automatic calculation
- 📤 **PDF export** for printing or sharing
- 💾 **localStorage persistence** for offline work

## Core Features

### 1. Planning Tab

**Day Cards:**
- Header with day name, date, collapse/expand button
- "Clear visits" button (removes visits, keeps day)
- Sunday cards: special green gradient styling
- "+ Add Visit" button per day
- Empty state message when no visits scheduled

**Visit Cards:**
Display in clean grid layout:
- Drag handle (⋮⋮) for reordering
- Client name
- Farm name
- Location
- Objective
- Completion checkbox
- Edit button (✏️) - opens modal
- Duplicate button (📋) - copies visit
- Delete button (×) - removes with confirmation

**Interactions:**
- **Double-click** any field: inline editing (Enter to save, Esc to cancel)
- **Drag & drop** visits: reorder within day or move to another day
- **Checkbox**: toggle completion status
- **Duplicate**: creates copy (always uncompleted)

### 2. Clients Tab

**Client Table:**
Displays all registered clients with:
- Name
- Farm
- City
- Location (smart display):
  - If `locationLink` exists: "Open in map" link
  - If `lat`+`lng` exist: displays coords + auto-generated Google Maps link
  - If only `locationText`: displays text
  - Otherwise: "—"
- Actions: Edit / Delete buttons

**Client Management:**
- Create new clients manually
- Auto-create when adding visits
- Edit all fields including location details
- Delete with confirmation

### 3. Header

**Info Fields:**
- Logo upload (60×60px, persisted as base64)
- Consultant name
- City
- Regional
- Base date (DatePicker)
- Company
- Supervisor

**Efficiency Badge:**
- Large circular display
- Auto-calculates: (completed visits / total visits) × 100
- Special Sunday rule: only counts if visit is completed

### 4. Data Persistence

**localStorage structure:**
```javascript
{
  consultor: string,
  cidade: string,
  regional: string,
  dataBase: ISO date string,
  empresa: string,
  supervisor: string,
  clients: [
    {
      name: string,
      farm: string,
      city?: string,
      locationText?: string,
      locationLink?: string,
      lat?: string,
      lng?: string
    }
  ],
  days: {
    [dayIndex: number]: [
      {
        client: string,
        farm: string,
        location: string,
        objective: string,
        completed: boolean
      }
    ]
  }
}
```

## Design System

### Colors (iOS-inspired)
```css
/* Primary */
--ios-blue: #007AFF;
--green-primary: #4ADE80;
--green-secondary: #3ECE72;

/* Backgrounds */
--bg-primary: #FFFFFF;
--bg-secondary: #F5F5F7;
--bg-gradient: linear-gradient(180deg, #F5F5F7 0%, #E5E5E7 100%);

/* Text */
--text-primary: #1D1D1F;
--text-secondary: #86868B;
--text-tertiary: #C7C7CC;

/* States */
--success: #34C759;
--error: #FF3B30;

/* Borders */
--border-default: #D1D1D6;
--border-soft: #E5E5E7;
```

### Typography
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;

/* Sizes */
--text-heading: 20px;
--text-body: 14px;
--text-caption: 12px;
--text-small: 10px;

/* Weights */
--weight-regular: 400;
--weight-medium: 500;
--weight-semibold: 600;
```

### Spacing
```css
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 12px;
--spacing-lg: 16px;
--spacing-xl: 20px;
--spacing-2xl: 24px;
```

### Border Radius
```css
--radius-sm: 6px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-xl: 16px;
```

## Implementation Guide

### Step 1: Create HTML Structure

Start with the container and tabs:
```html
<div class="container">
  <!-- Header -->
  <div class="header">
    <!-- Logo, fields, efficiency badge -->
  </div>

  <!-- Tabs -->
  <div class="tabs-container">
    <button class="tab-btn active">Planning</button>
    <button class="tab-btn">Clients</button>
  </div>

  <!-- Tab Content -->
  <div class="tab-content active" id="planningTab">
    <div id="daysContainer"></div>
  </div>

  <div class="tab-content" id="clientsTab">
    <div id="clientsTableContainer"></div>
  </div>
</div>
```

### Step 2: Initialize State Management

```javascript
let state = {
  consultor: '',
  cidade: '',
  regional: '',
  dataBase: '',
  empresa: '',
  supervisor: '',
  clients: [],
  days: {}
};

// Load from localStorage
function loadState() {
  const stored = localStorage.getItem('weeklyPlanner');
  if (stored) {
    state = JSON.parse(stored);
  }
}

// Save to localStorage
function saveState() {
  localStorage.setItem('weeklyPlanner', JSON.stringify(state));
}
```

### Step 3: Render Days Dynamically

```javascript
function renderDays() {
  const container = document.getElementById('daysContainer');
  const baseDate = new Date(state.dataBase || new Date());
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  
  const indices = Object.keys(state.days).sort((a, b) => a - b);
  
  indices.forEach(idx => {
    const date = new Date(baseDate);
    date.setDate(date.getDate() + parseInt(idx));
    const dayOfWeek = date.getDay();
    const isSunday = dayOfWeek === 0;
    
    // Create day card with visits
    // Apply special styling for Sunday
  });
}
```

### Step 4: Implement Drag & Drop

```javascript
let draggedVisit = null;
let draggedFromDay = null;
let draggedFromIndex = null;

function handleDragStart(e) {
  draggedFromDay = parseInt(e.currentTarget.dataset.day);
  draggedFromIndex = parseInt(e.currentTarget.dataset.visit);
  draggedVisit = state.days[draggedFromDay][draggedFromIndex];
  e.currentTarget.classList.add('dragging');
}

function handleDrop(e) {
  const dropDay = parseInt(e.currentTarget.dataset.day);
  const dropIndex = parseInt(e.currentTarget.dataset.visit);
  
  // Reorder or move between days
  if (draggedFromDay === dropDay) {
    // Reorder within same day
    const visits = state.days[dropDay];
    visits.splice(draggedFromIndex, 1);
    visits.splice(dropIndex, 0, draggedVisit);
  } else {
    // Move to different day
    state.days[draggedFromDay].splice(draggedFromIndex, 1);
    state.days[dropDay].push(draggedVisit);
  }
  
  saveState();
  renderDays();
}
```

### Step 5: Inline Editing

```javascript
function startInlineEdit(dayIdx, visitIdx, field, element) {
  const textElement = element.querySelector('.visit-text');
  const currentValue = textElement.textContent;
  
  const input = document.createElement('input');
  input.value = currentValue;
  input.className = 'visit-text';
  
  textElement.replaceWith(input);
  element.classList.add('editing');
  input.focus();
  input.select();
  
  const saveEdit = () => {
    const newValue = input.value.trim();
    if (newValue && newValue !== currentValue) {
      state.days[dayIdx][visitIdx][field] = newValue;
      saveState();
    }
    
    const newText = document.createElement('div');
    newText.className = 'visit-text';
    newText.textContent = newValue || currentValue;
    input.replaceWith(newText);
    element.classList.remove('editing');
  };
  
  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') saveEdit();
  });
  input.addEventListener('blur', saveEdit);
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      input.replaceWith(textElement);
      element.classList.remove('editing');
    }
  });
}

// Attach to visit fields
document.querySelectorAll('.visit-info').forEach(info => {
  info.addEventListener('dblclick', (e) => {
    const card = e.currentTarget.closest('.visit-card');
    const dayIdx = parseInt(card.dataset.day);
    const visitIdx = parseInt(card.dataset.visit);
    const field = e.currentTarget.dataset.field;
    startInlineEdit(dayIdx, visitIdx, field, e.currentTarget);
  });
});
```

### Step 6: Efficiency Calculation

```javascript
function updateEfficiency() {
  let total = 0;
  let completed = 0;
  const baseDate = new Date(state.dataBase || new Date());

  Object.keys(state.days).forEach(dayIdx => {
    const date = new Date(baseDate);
    date.setDate(date.getDate() + parseInt(dayIdx));
    const isSunday = date.getDay() === 0;
    
    state.days[dayIdx].forEach(visit => {
      if (isSunday) {
        // Sunday: only count if completed
        if (visit.completed) {
          total++;
          completed++;
        }
      } else {
        // Other days: always count
        total++;
        if (visit.completed) completed++;
      }
    });
  });

  const percent = total === 0 ? 0 : Math.round((completed / total) * 100);
  document.getElementById('efficiencyPercent').textContent = percent + '%';
}
```

### Step 7: PDF Export

```javascript
async function exportPDF() {
  const { jsPDF } = window.jspdf;
  const pdf = new jsPDF();
  
  // Add header info
  pdf.setFontSize(16);
  pdf.text('Weekly Planner', 20, 20);
  
  pdf.setFontSize(10);
  pdf.text(`Consultant: ${state.consultor}`, 20, 30);
  pdf.text(`City: ${state.cidade}`, 20, 36);
  pdf.text(`Regional: ${state.regional}`, 20, 42);
  
  // Add days and visits
  let y = 60;
  Object.keys(state.days).sort().forEach(dayIdx => {
    const date = new Date(state.dataBase);
    date.setDate(date.getDate() + parseInt(dayIdx));
    
    pdf.setFontSize(12);
    pdf.text(`Day ${dayIdx}: ${date.toLocaleDateString()}`, 20, y);
    y += 8;
    
    state.days[dayIdx].forEach(visit => {
      pdf.setFontSize(9);
      pdf.text(`  • ${visit.client} - ${visit.farm}`, 25, y);
      y += 6;
    });
    y += 4;
  });
  
  pdf.save('weekly-planner.pdf');
}
```

## Advanced Features

### Smart Client Creation
When adding a visit, automatically create client if not exists:
```javascript
function saveVisit() {
  const name = document.getElementById('visitClientName').value.trim();
  const farm = document.getElementById('visitClientFarm').value.trim();
  
  // Auto-create client
  const exists = state.clients.find(c => 
    c.name.toLowerCase() === name.toLowerCase() && 
    c.farm.toLowerCase() === farm.toLowerCase()
  );
  
  if (!exists) {
    state.clients.push({ name, farm, city: '', locationText: '', locationLink: '', lat: '', lng: '' });
  }
  
  // Add visit
  state.days[currentDayIndex].push({
    client: name,
    farm: farm,
    location: location,
    objective: objective,
    completed: false
  });
  
  saveState();
  renderDays();
}
```

### Duplicate Visit
```javascript
function duplicateVisit(dayIdx, visitIdx) {
  const original = state.days[dayIdx][visitIdx];
  
  const duplicate = {
    client: original.client,
    farm: original.farm,
    location: original.location,
    objective: original.objective,
    completed: false // Always start uncompleted
  };
  
  // Insert after original
  state.days[dayIdx].splice(visitIdx + 1, 0, duplicate);
  
  saveState();
  renderDays();
}
```

### Google Maps Integration
```javascript
function formatClientLocation(client) {
  if (client.locationLink) {
    return `<a href="${client.locationLink}" target="_blank">Open in map</a>`;
  }
  
  if (client.lat && client.lng) {
    const url = `https://www.google.com/maps?q=${client.lat},${client.lng}`;
    return `<a href="${url}" target="_blank">${client.lat}, ${client.lng}</a>`;
  }
  
  if (client.locationText) {
    return client.locationText;
  }
  
  return '—';
}
```

## Responsive Design

### Mobile (<768px)
```css
@media (max-width: 768px) {
  .header-fields {
    grid-template-columns: 1fr;
  }
  
  .visit-card {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  
  .clients-table {
    display: block;
    overflow-x: auto;
  }
}
```

### Tablet/Desktop (≥768px)
```css
.header-fields {
  grid-template-columns: 1fr 1fr 1fr;
}

.visit-card {
  grid-template-columns: 20px 1fr 1fr 1fr 1.5fr auto auto auto auto;
}
```

## Best Practices

### Performance
- ✅ Use event delegation for dynamically rendered elements
- ✅ Debounce localStorage saves (not implemented but recommended)
- ✅ Lazy render collapsed days
- ✅ Virtual scrolling for 100+ visits (advanced)

### UX
- ✅ Confirm before destructive actions (delete, clear)
- ✅ Auto-save on every change
- ✅ Visual feedback for all interactions
- ✅ Loading states for async operations
- ✅ Empty states with helpful messages

### Accessibility
- ✅ Semantic HTML (sections, articles, buttons)
- ✅ ARIA labels for icon buttons
- ✅ Keyboard navigation (Tab, Enter, Esc)
- ✅ Focus indicators
- ✅ Color contrast (WCAG AA minimum)

### Data Integrity
- ✅ Validate required fields
- ✅ Handle edge cases (empty days, no clients)
- ✅ Backwards compatibility for data migrations
- ✅ Export/import functionality for backups

## Integration Examples

### As React Component
Convert to React with hooks:
```jsx
const WeeklyPlanner = () => {
  const [state, setState] = useState(initialState);
  
  useEffect(() => {
    loadState();
  }, []);
  
  useEffect(() => {
    saveState(state);
  }, [state]);
  
  return (
    <div className="container">
      <Header state={state} setState={setState} />
      <Tabs>
        <PlanningTab days={state.days} />
        <ClientsTab clients={state.clients} />
      </Tabs>
    </div>
  );
};
```

### As Vue Component
```vue
<template>
  <div class="container">
    <Header v-model="state" />
    <Tabs>
      <PlanningTab :days="state.days" />
      <ClientsTab :clients="state.clients" />
    </Tabs>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';

const state = ref({});

onMounted(() => {
  loadState();
});

watch(state, () => {
  saveState();
}, { deep: true });
</script>
```

### Backend Integration
Replace localStorage with API calls:
```javascript
async function saveState() {
  await fetch('/api/planner', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(state)
  });
}

async function loadState() {
  const response = await fetch('/api/planner');
  state = await response.json();
}
```

## Troubleshooting

### Drag & Drop not working
- Check `draggable="true"` attribute
- Ensure data-attributes are present
- Verify event listeners are attached after render

### Inline editing not saving
- Check Enter key event listener
- Verify blur event is attached
- Ensure saveState() is called

### Efficiency always 0%
- Check base date is set
- Verify day indices are integers
- Ensure visits array exists

### PDF export fails
- Include jsPDF library via CDN
- Check for console errors
- Ensure all data is loaded before export

## Dependencies

```html
<!-- jsPDF for PDF export -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>

<!-- html2canvas for capturing screenshots (optional) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
```

## License

MIT - Feel free to use in commercial or personal projects

---

**Created for**: Agricultural consultants, field service management, CRM modules, scheduling systems

**Tech stack**: Vanilla JS, HTML5, CSS3, localStorage, optional: React/Vue/Angular integration

**Browser support**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
