import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/infra/preferences_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/enums/agenda_view.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';

part 'agenda_filters_provider.g.dart';

/// Critérios de filtro da agenda (DTO imutável).
class AgendaFilterCriteria {
  final Set<EventType> types;
  final Set<EventStatus> statuses;
  final String? clienteId;
  final String? fazendaId;

  const AgendaFilterCriteria({
    this.types = const {},
    this.statuses = const {},
    this.clienteId,
    this.fazendaId,
  });

  bool get hasActiveFilters =>
      types.isNotEmpty ||
      statuses.isNotEmpty ||
      clienteId != null ||
      fazendaId != null;

  AgendaFilterCriteria copyWith({
    Set<EventType>? types,
    Set<EventStatus>? statuses,
    String? clienteId,
    String? fazendaId,
    bool clearCliente = false,
    bool clearFazenda = false,
  }) {
    return AgendaFilterCriteria(
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      clienteId: clearCliente ? null : (clienteId ?? this.clienteId),
      fazendaId: clearFazenda ? null : (fazendaId ?? this.fazendaId),
    );
  }

  AgendaFilterCriteria clear() => const AgendaFilterCriteria();

  Map<String, dynamic> toJson() {
    return {
      'types': types.map((t) => t.name).toList(),
      'statuses': statuses.map((s) => s.name).toList(),
      'clienteId': clienteId,
      'fazendaId': fazendaId,
    };
  }

  factory AgendaFilterCriteria.fromJson(Map<String, dynamic> json) {
    return AgendaFilterCriteria(
      types:
          (json['types'] as List<dynamic>?)
              ?.map((t) => EventType.values.byName(t as String))
              .toSet() ??
          {},
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((s) => EventStatus.values.byName(s as String))
              .toSet() ??
          {},
      clienteId: json['clienteId'] as String?,
      fazendaId: json['fazendaId'] as String?,
    );
  }
}

/// Filtros persistidos da agenda — ADR-008 (Fase 4: @riverpod).
@Riverpod(keepAlive: true)
class AgendaFilters extends _$AgendaFilters {
  static const _prefsKey = 'agenda_filters';

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  @override
  AgendaFilterCriteria build() {
    Future.microtask(_loadFromPreferences);
    return const AgendaFilterCriteria();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final raw = _prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      state = AgendaFilterCriteria.fromJson(decoded);
    } catch (e) {
      AppLogger.warning(
        'Falha ao carregar filtros da agenda — usando padrão',
        tag: 'AgendaFilters',
        error: e,
      );
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      await _prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    } catch (e) {
      AppLogger.warning(
        'Falha ao salvar filtros da agenda',
        tag: 'AgendaFilters',
        error: e,
      );
    }
  }

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

  void setCliente(String? clienteId) {
    state = state.copyWith(
      clienteId: clienteId,
      clearCliente: clienteId == null,
    );
    _saveToPreferences();
  }

  void setFazenda(String? fazendaId) {
    state = state.copyWith(
      fazendaId: fazendaId,
      clearFazenda: fazendaId == null,
    );
    _saveToPreferences();
  }

  void clearAll() {
    state = state.clear();
    _saveToPreferences();
  }
}

final agendaViewProvider = StateProvider<AgendaView>(
  (ref) => AgendaView.calendario,
);

final agendaHasUnsavedChangesProvider = StateProvider<bool>((ref) => false);
