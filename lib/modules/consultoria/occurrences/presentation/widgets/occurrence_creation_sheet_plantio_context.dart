part of 'occurrence_creation_sheet.dart';

/// Estádio da soja pelos dias após a emergência (ADR-059).
///
/// `EstadioData.dap` conta a partir de VE = 0, ou seja, é DAE. O seed não é
/// monotônico (R6/R7 abaixo de R5.5): vence o maior `dap` ≤ [dae]; empate
/// fica com o primeiro da lista. Cultura informada que não seja soja → null.
EstadioData? suggestedEstadioForDae({required int? dae, String? cultura}) {
  if (dae == null || dae < 0) return null;
  final crop = cultura?.trim().toLowerCase() ?? '';
  if (crop.isNotEmpty && !crop.contains('soja')) return null;
  EstadioData? best;
  for (final estadio in kEstadios) {
    if (estadio.dap > dae) continue;
    if (best == null || estadio.dap > best.dap) best = estadio;
  }
  return best;
}

/// Valores de plantio que vão para a ocorrência ao salvar.
typedef _PlantioSubmitValues = ({
  String? cultivar,
  String? cultura,
  String? safra,
  String? dataPlantio,
  String? dataFimPlantio,
  String? dataEmergencia,
  int? cicloDias,
});

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

extension _OccurrenceCreationSheetPlantioContext
    on _OccurrenceCreationSheetState {
  /// Data da ocorrência em edição; null (agora) na criação.
  DateTime? get _plantioReferenceDate => widget.initialOccurrence?.createdAt;

  /// Criação: talhão do prefill. Edição: talhão salvo ou o do pin.
  /// Build observa ([watch]); o submit lê o mesmo talhão sem observar.
  String? _plantioFieldId({required bool watch}) {
    final occurrence = widget.initialOccurrence;
    final own = occurrence == null
        ? widget.talhaoPrefill?.fieldId
        : occurrence.fieldId;
    if (own != null && own.trim().isNotEmpty) return own.trim();
    if (occurrence == null) return null;
    final location = occurrenceLocationProvider(_locationQuery);
    return (watch ? ref.watch(location) : ref.read(location))
        .valueOrNull
        ?.fieldId;
  }

  /// Chamado no build: resolve o contexto e guarda o card somente leitura.
  void _watchPlantioContext() {
    final fieldId = _plantioFieldId(watch: true);
    final context = fieldId == null
        ? null
        : ref
              .watch(
                occurrencePlantioContextProvider((
                  fieldId: fieldId,
                  referenceDate: _plantioReferenceDate,
                )),
              )
              .valueOrNull;
    final effective = _effectivePlantioContext(context);
    _plantioSummary = _isAreaVisitada || _isPlantio ? null : effective;
    _schedulePlantioContextEffects(context, effective);
  }

  /// Edição mescla: valores da ocorrência primeiro, vazios do contexto.
  OccurrencePlantioContext? _effectivePlantioContext(
    OccurrencePlantioContext? context,
  ) {
    if (context == null) return null;
    final occurrence = widget.initialOccurrence;
    final effective = occurrence == null
        ? context
        : mergeOccurrencePlantioContext(occurrence, context);
    return effective.isEmpty ? null : effective;
  }

  void _schedulePlantioContextEffects(
    OccurrencePlantioContext? context,
    OccurrencePlantioContext? effective,
  ) {
    if (context == null || effective == null) return;
    final fillPlantio =
        widget.initialOccurrence == null &&
        _isPlantio &&
        !_plantioContextApplied;
    final suggest = !_estadioSuggestionDone && !_isAreaVisitada;
    if (!fillPlantio && !suggest) return;
    if (fillPlantio) _plantioContextApplied = true;
    if (suggest) _estadioSuggestionDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (fillPlantio) _fillPlantioFromContext(context);
      final estadio = suggest && _estadio == null
          ? suggestedEstadioForDae(
              dae: occurrenceCalendarAgeDays(
                parseOccurrenceIsoDate(effective.dataEmergencia),
                _plantioReferenceDate ?? DateTime.now(),
              ),
              cultura: effective.cultura,
            )
          : null;
      _notifyStateChanged(() {
        if (estadio != null) {
          _estadio = estadio;
          _estadioSugerido = true;
        }
      });
    });
  }

  /// Plantio novo no talhão: campos vazios recebem o plantio vigente.
  void _fillPlantioFromContext(OccurrencePlantioContext context) {
    void fill(TextEditingController controller, String? value) {
      if (controller.text.trim().isEmpty && value != null) {
        controller.text = value;
      }
    }

    fill(_culturaCtrl, context.cultura);
    fill(_cultivarCtrl, context.cultivar);
    fill(_safraCtrl, context.safra);
    fill(_cicloDiasCtrl, context.cicloDias?.toString());
    _dataPlantio ??= parseOccurrenceIsoDate(context.dataPlantio);
    _dataFimPlantio ??= parseOccurrenceIsoDate(context.dataFimPlantio);
    _dataEmergencia ??= parseOccurrenceIsoDate(context.dataEmergencia);
  }

  void _selectEstadio(EstadioData? estadio) => _patchForm(() {
    _estadio = estadio;
    _estadioSugerido = false;
  });

  Widget? _buildEstadioSugeridoHint(Color muted) {
    if (!_estadioSugerido || _estadio == null) return null;
    return Padding(
      key: const Key('occurrence_estadio_sugerido_hint'),
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        'Sugerido pelos dias de lavoura',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    );
  }

  /// Com contexto: card somente leitura. Sem: bloco editável de antes.
  Widget _buildPlantioDataBlock() {
    final summary = _plantioSummary;
    if (summary == null) return _buildCultivarPlantioBlock();
    return OccurrencePlantioSummaryCard(
      plantio: summary,
      referenceDate: _plantioReferenceDate,
    );
  }

  List<Widget> _buildCulturaSafraFields() => [
    const SizedBox(height: 10),
    OccurrenceDarkField(
      controller: _culturaCtrl,
      label: 'Cultura',
      hint: 'ex.: Soja',
    ),
    const SizedBox(height: 10),
    OccurrenceDarkField(
      controller: _safraCtrl,
      label: 'Safra',
      hint: 'ex.: 2026/2027',
    ),
  ];

  /// Card somente leitura ativo: valores do contexto (na edição já mesclados
  /// com os da ocorrência). Senão, os campos do formulário.
  _PlantioSubmitValues _plantioValuesForSubmit() {
    final summary = _plantioSummary;
    if (summary != null) {
      return (
        cultivar: summary.cultivar,
        cultura: summary.cultura,
        safra: summary.safra,
        dataPlantio: summary.dataPlantio,
        dataFimPlantio: summary.dataFimPlantio,
        dataEmergencia: summary.dataEmergencia,
        cicloDias: summary.cicloDias,
      );
    }
    final inicio = _dataPlantio;
    final safra =
        _trimmedOrNull(_safraCtrl.text) ??
        (_isPlantio && inicio != null ? safraFromPlantio(inicio) : null);
    return (
      cultivar: _trimmedOrNull(_cultivarCtrl.text),
      cultura: _trimmedOrNull(_culturaCtrl.text),
      safra: safra,
      dataPlantio: _isoDate(inicio),
      dataFimPlantio: _isoDate(_dataFimPlantio),
      dataEmergencia: _isoDate(_dataEmergencia),
      cicloDias: parseOccurrenceCicloDias(_cicloDiasCtrl.text),
    );
  }

  /// Plantios do talhão já carregados pelo contexto observado no build.
  /// Lido antes do confirm (o host fecha o sheet ao salvar). Ainda sem
  /// valor → null, e a edição não grava no talhão.
  List<Occurrence>? _loadedPlantiosForWriteBack(String? fieldId) {
    if (widget.initialOccurrence == null || !_isPlantio) return null;
    if (fieldId == null || fieldId.trim().isEmpty) return null;
    return ref
        .read(occurrencePlantioOccurrencesProvider(fieldId.trim()))
        .valueOrNull;
  }

  /// Criação de Plantio sempre grava; edição só se for o mais recente da safra.
  bool _shouldWriteBackPlantio({
    required String fieldId,
    required _PlantioSubmitValues values,
    required List<Occurrence>? plantios,
  }) {
    if (!_isPlantio) return false;
    final occurrence = widget.initialOccurrence;
    if (occurrence == null) return true;
    if (plantios == null) return false;
    final edited = occurrence.copyWith(
      category: 'plantio',
      fieldId: fieldId,
      safra: values.safra,
      clearSafra: values.safra == null,
      dataPlantio: values.dataPlantio,
      clearDataPlantio: values.dataPlantio == null,
    );
    return isLatestPlantioInSafra(
      fieldId: fieldId,
      plantio: edited,
      plantioOccurrences: plantios,
    );
  }
}
