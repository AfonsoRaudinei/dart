part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetDraft on _OccurrenceCreationSheetState {
  String get _draftPinKey =>
      OccurrenceFormDraft.pinKeyFor(_pinLatitude, _pinLongitude);

  void _restoreDraftIfAny() {
    if (widget.initialOccurrence != null) return;

    final draft = ref.read(occurrenceDraftProvider(_draftPinKey));
    if (draft == null || draft.isEffectivelyEmpty) return;

    _cultivarCtrl.text = draft.cultivar;
    _descCtrl.text = draft.description;
    _recomCtrl.text = draft.recomendacoes;
    _urgency = draft.urgency;
    _selectedCategoryValue = draft.selectedCategoryValue;
    _dataPlantio = draft.dataPlantioIso != null
        ? DateTime.tryParse(draft.dataPlantioIso!)
        : null;
    _estadio = _findEstadio(draft.estadioCode);

    _cats
      ..clear()
      ..addAll(
        draft.categoryNames
            .map(_categoryFromName)
            .whereType<OccurrenceCategory>(),
      );

    _metrics
      ..clear()
      ..addAll(
        draft.metrics.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ),
      );
    _nutrientes
      ..clear()
      ..addAll(draft.nutrientes);
    _fotos
      ..clear()
      ..addAll(
        draft.fotos.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );

    for (final entry in draft.notas.entries) {
      _notaCtrl(entry.key).text = entry.value;
    }

    if (draft.clientId != null) {
      unawaited(_prefillClientFromDraft(draft.clientId!));
    }
  }

  OccurrenceCategory? _categoryFromName(String name) {
    for (final category in OccurrenceCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }

  Future<void> _prefillClientFromDraft(String clientId) async {
    try {
      final clients = await _clientsFuture;
      if (!mounted) return;
      final selected =
          clients.where((client) => client.id == clientId).firstOrNull;
      if (selected != null) {
        setState(() => _selectedClient = selected);
      }
    } catch (_) {
      // Cliente pode ter sido removido — rascunho segue sem pré-seleção.
    }
  }

  void _persistDraft() {
    if (widget.initialOccurrence != null) return;

    final draft = OccurrenceFormDraft(
      clientId: _selectedClient?.id,
      cultivar: _cultivarCtrl.text,
      dataPlantioIso: _isoDate(_dataPlantio),
      estadioCode: _estadio?.code,
      selectedCategoryValue: _selectedCategoryValue,
      categoryNames: _cats.map((cat) => cat.name).toList(),
      urgency: _urgency,
      description: _descCtrl.text,
      recomendacoes: _recomCtrl.text,
      metrics: _metrics.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      ),
      nutrientes: Set<String>.from(_nutrientes),
      fotos: _fotos.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      notas: _notasCtrls.map((key, ctrl) => MapEntry(key, ctrl.text)),
    );

    if (draft.isEffectivelyEmpty) {
      ref.read(occurrenceDraftProvider(_draftPinKey).notifier).state = null;
      return;
    }

    ref.read(occurrenceDraftProvider(_draftPinKey).notifier).state = draft;
  }

  void _clearDraft() {
    ref.read(occurrenceDraftProvider(_draftPinKey).notifier).state = null;
  }

  void _patchForm(VoidCallback fn) {
    setState(fn);
    _persistDraft();
  }
}
