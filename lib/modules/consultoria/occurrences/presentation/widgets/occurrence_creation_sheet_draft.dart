part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetDraft on _OccurrenceCreationSheetState {
  String get _draftPinKey =>
      OccurrenceFormDraft.pinKeyFor(_pinLatitude, _pinLongitude);

  void _restoreDraftIfAny() {
    if (widget.initialOccurrence != null) return;

    final draft = ref.read(occurrenceDraftProvider(_draftPinKey));
    if (draft == null || draft.isEffectivelyEmpty) return;

    _cultivarCtrl.text = draft.cultivar;
    _culturaCtrl.text = draft.cultura;
    _safraCtrl.text = draft.safra;
    _descCtrl.text = draft.description;
    _ordem.acao.text = draft.recomendacaoAcao;
    _ordem.dose.text = draft.recomendacaoDose;
    _ordem.quando.text = draft.recomendacaoQuando;
    _urgency = draft.urgency;
    _selectedCategoryValue = draft.selectedCategoryValue;
    _dataPlantio = draft.dataPlantioIso != null
        ? DateTime.tryParse(draft.dataPlantioIso!)
        : null;
    _dataEmergencia = draft.dataEmergenciaIso != null
        ? DateTime.tryParse(draft.dataEmergenciaIso!)
        : null;
    _dataFimPlantio = draft.dataFimPlantioIso != null
        ? DateTime.tryParse(draft.dataFimPlantioIso!)
        : null;
    _cicloDiasCtrl.text = draft.cicloDias;
    _sementesPorMetroCtrl.text = draft.sementesPorMetro;
    _estandePlantasCtrl.text = draft.estandePlantas;
    _avaliacaoPlantio = draft.avaliacaoPlantio;
    _objetivoPlantioCtrl.text = draft.objetivoPlantio;
    _amostraCodigoCtrl.text = draft.amostraCodigo;
    _amostraColetorCtrl.text = draft.amostraColetor;
    _amostraLaudoCtrl.text = draft.amostraLaudo;
    _amostraTramite = OccurrenceAmostraTramite.fromStorage(
      draft.amostraTramiteStorage,
    );
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
    _photoCaptions
      ..clear()
      ..addAll(Map<String, String>.from(draft.photoCaptions));
    _audioPath = draft.audioPath;
    _audioDurationSec = draft.audioDurationSec;

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
      final selected = clients
          .where((client) => client.id == clientId)
          .firstOrNull;
      if (selected != null) {
        _notifyStateChanged(() => _selectedClient = selected);
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
      cultura: _culturaCtrl.text,
      safra: _safraCtrl.text,
      dataPlantioIso: _isoDate(_dataPlantio),
      dataEmergenciaIso: _isoDate(_dataEmergencia),
      dataFimPlantioIso: _isoDate(_dataFimPlantio),
      cicloDias: _cicloDiasCtrl.text,
      sementesPorMetro: _sementesPorMetroCtrl.text,
      estandePlantas: _estandePlantasCtrl.text,
      avaliacaoPlantio: _avaliacaoPlantio,
      objetivoPlantio: _objetivoPlantioCtrl.text,
      estadioCode: _estadio?.code,
      selectedCategoryValue: _selectedCategoryValue,
      categoryNames: _cats.map((cat) => cat.name).toList(),
      urgency: _urgency,
      description: _descCtrl.text,
      recomendacaoAcao: _ordem.acao.text,
      recomendacaoDose: _ordem.dose.text,
      recomendacaoQuando: _ordem.quando.text,
      metrics: _metrics.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      ),
      nutrientes: Set<String>.from(_nutrientes),
      fotos: _fotos.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      photoCaptions: Map<String, String>.from(_photoCaptions),
      notas: _notasCtrls.map((key, ctrl) => MapEntry(key, ctrl.text)),
      audioPath: _audioPath,
      audioDurationSec: _audioDurationSec,
      amostraCodigo: _amostraCodigoCtrl.text,
      amostraColetor: _amostraColetorCtrl.text,
      amostraLaudo: _amostraLaudoCtrl.text,
      amostraTramiteStorage: _amostraTramite?.storageValue,
    );

    if (draft.isEffectivelyEmpty) {
      ref.read(occurrenceDraftProvider(_draftPinKey).notifier).state = null;
      return;
    }

    ref.read(occurrenceDraftProvider(_draftPinKey).notifier).state = draft;
  }

  void _patchForm(VoidCallback fn) {
    _notifyStateChanged(fn);
    _persistDraft();
  }

  void _onCicloDiasChanged() => _patchForm(() {});

  void _applyTalhaoPrefillFields() {
    if (widget.initialOccurrence != null) return;
    final draft = ref.read(occurrenceDraftProvider(_draftPinKey));
    final patch = applyTalhaoPrefill(
      prefill: widget.talhaoPrefill,
      isEditing: false,
      currentCultivar: _cultivarCtrl.text,
      currentDataPlantio: _isoDate(_dataPlantio),
      currentDataEmergencia: _isoDate(_dataEmergencia),
      currentCicloDias: _cicloDiasCtrl.text,
      draftHasClient: draft?.clientId?.trim().isNotEmpty == true,
      currentCultura: _culturaCtrl.text,
    );
    if (patch.cultura != null) _culturaCtrl.text = patch.cultura!;
    if (patch.cultivar != null) _cultivarCtrl.text = patch.cultivar!;
    if (patch.dataPlantio != null) {
      _dataPlantio = DateTime.tryParse(patch.dataPlantio!);
    }
    if (patch.dataEmergencia != null) {
      _dataEmergencia = DateTime.tryParse(patch.dataEmergencia!);
    }
    if (patch.cicloDias != null) _cicloDiasCtrl.text = patch.cicloDias!;
  }

  Future<void> _prefillActiveVisitClient() async {
    final draft = ref.read(occurrenceDraftProvider(_draftPinKey));
    if (draft?.clientId?.trim().isNotEmpty == true) return;

    try {
      final clients = await _clientsFuture;
      if (!mounted || _selectedClient != null) return;

      final patch = applyTalhaoPrefill(
        prefill: widget.talhaoPrefill,
        isEditing: widget.initialOccurrence != null,
        currentCultivar: _cultivarCtrl.text,
        currentDataPlantio: _isoDate(_dataPlantio),
        currentDataEmergencia: _isoDate(_dataEmergencia),
        currentCicloDias: _cicloDiasCtrl.text,
        draftHasClient: false,
      );
      if (patch.applyClient) {
        final selected = clients
            .where((client) => client.id == widget.talhaoPrefill!.clientId)
            .firstOrNull;
        if (selected != null) {
          _notifyStateChanged(() => _selectedClient = selected);
          return;
        }
      }

      final activeContext = await ref
          .read(activeVisitContextLookupProvider)
          .getActiveContext();
      if (!mounted || _selectedClient != null) return;

      if (activeContext != null) {
        final selected = clients
            .where((client) => client.id == activeContext.clientId)
            .firstOrNull;
        if (selected != null) {
          _notifyStateChanged(() => _selectedClient = selected);
          return;
        }
      }

      final role = ref.read(currentUserRoleProvider);
      if (role.isProdutor && clients.isNotEmpty) {
        _notifyStateChanged(() => _selectedClient = clients.first);
      }
    } catch (_) {
      // Ocorrências continuam disponíveis fora de uma visita ativa.
    }
  }
}
