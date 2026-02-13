import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';

/// Filtros disponíveis para a agenda
class AgendaFilters {
  final Set<EventType> types;
  final Set<EventStatus> statuses;
  final String? clienteId;
  final String? fazendaId;

  const AgendaFilters({
    this.types = const {},
    this.statuses = const {},
    this.clienteId,
    this.fazendaId,
  });

  bool get hasActiveFilters =>
      types.isNotEmpty || statuses.isNotEmpty || clienteId != null || fazendaId != null;

  AgendaFilters copyWith({
    Set<EventType>? types,
    Set<EventStatus>? statuses,
    String? clienteId,
    String? fazendaId,
    bool clearCliente = false,
    bool clearFazenda = false,
  }) {
    return AgendaFilters(
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      clienteId: clearCliente ? null : (clienteId ?? this.clienteId),
      fazendaId: clearFazenda ? null : (fazendaId ?? this.fazendaId),
    );
  }

  AgendaFilters clear() {
    return const AgendaFilters();
  }

  // Serialização para SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'types': types.map((t) => t.name).toList(),
      'statuses': statuses.map((s) => s.name).toList(),
      'clienteId': clienteId,
      'fazendaId': fazendaId,
    };
  }

  factory AgendaFilters.fromJson(Map<String, dynamic> json) {
    return AgendaFilters(
      types: (json['types'] as List<dynamic>?)
              ?.map((t) => EventType.values.byName(t as String))
              .toSet() ??
          {},
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((s) => EventStatus.values.byName(s as String))
              .toSet() ??
          {},
      clienteId: json['clienteId'] as String?,
      fazendaId: json['fazendaId'] as String?,
    );
  }
}

/// Notifier para gerenciar filtros
class AgendaFiltersNotifier extends StateNotifier<AgendaFilters> {
  AgendaFiltersNotifier() : super(const AgendaFilters()) {
    _loadFromPreferences();
  }

  static const _prefsKey = 'agenda_filters';

  /// Carrega filtros salvos
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      
      if (json != null) {
        // Parse JSON manually to avoid dependency issues
        // For now, start with empty filters
        // TODO: Implement proper JSON parsing
      }
    } catch (e) {
      // Ignore errors, start with empty filters
    }
  }

  /// Salva filtros
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // TODO: Serialize and save
      await prefs.setString(_prefsKey, '{}');
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Toggle tipo
  void toggleType(EventType type) {
    final newTypes = Set<EventType>.from(state.types);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    state = state.copyWith(types: newTypes);
    _saveToPreferences();
  }

  /// Toggle status
  void toggleStatus(EventStatus status) {
    final newStatuses = Set<EventStatus>.from(state.statuses);
    if (newStatuses.contains(status)) {
      newStatuses.remove(status);
    } else {
      newStatuses.add(status);
    }
    state = state.copyWith(statuses: newStatuses);
    _saveToPreferences();
  }

  /// Filtrar por cliente
  void setCliente(String? clienteId) {
    state = state.copyWith(
      clienteId: clienteId,
      clearCliente: clienteId == null,
    );
    _saveToPreferences();
  }

  /// Filtrar por fazenda
  void setFazenda(String? fazendaId) {
    state = state.copyWith(
      fazendaId: fazendaId,
      clearFazenda: fazendaId == null,
    );
    _saveToPreferences();
  }

  /// Limpar todos os filtros
  void clearAll() {
    state = state.clear();
    _saveToPreferences();
  }
}

/// Provider de filtros
final agendaFiltersProvider =
    StateNotifierProvider<AgendaFiltersNotifier, AgendaFilters>(
  (ref) => AgendaFiltersNotifier(),
);
