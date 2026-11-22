part of 'occurrence_creation_sheet.dart';

enum _PlantioPhaseChip { validacaoPendente, execucaoNaoAcompanhada, completo }

extension _OccurrenceCreationSheetPlantioPhases
    on _OccurrenceCreationSheetState {
  bool _hasPlantioExecucaoContent() {
    if (_dataPlantio != null || _dataFimPlantio != null) return true;
    if (_sementesPorMetroCtrl.text.trim().isNotEmpty) return true;
    if (_avaliacaoPlantio != null) return true;
    if (_objetivoPlantioCtrl.text.trim().isNotEmpty) return true;
    return false;
  }

  bool _hasPlantioEmergenciaContent() {
    if (_dataEmergencia != null || _dataValidacao != null) return true;
    if (_avaliacaoEmergencia != null) return true;
    if (_estandePlantasCtrl.text.trim().isNotEmpty) return true;
    return false;
  }

  bool _canSavePlantioOccurrence() {
    final exec = _hasPlantioExecucaoContent();
    final emerg = _hasPlantioEmergenciaContent();
    final cultivarEmerg = _cultivarCtrl.text.trim().isNotEmpty && emerg;
    return exec || emerg || cultivarEmerg;
  }

  bool _emergenciaPhaseClosed() {
    if (_dataEmergencia == null) return false;
    return _dataValidacao != null || _avaliacaoEmergencia != null;
  }

  _PlantioPhaseChip? _plantioPhaseChip() {
    final execCore =
        _dataPlantio != null ||
        _dataFimPlantio != null ||
        _sementesPorMetroCtrl.text.trim().isNotEmpty ||
        _avaliacaoPlantio != null;
    final emerg = _hasPlantioEmergenciaContent();

    if (emerg && !execCore) {
      return _emergenciaPhaseClosed()
          ? _PlantioPhaseChip.completo
          : _PlantioPhaseChip.execucaoNaoAcompanhada;
    }
    if (execCore && !_emergenciaPhaseClosed()) {
      return _PlantioPhaseChip.validacaoPendente;
    }
    if (_emergenciaPhaseClosed() && (execCore || emerg)) {
      return _PlantioPhaseChip.completo;
    }
    return null;
  }

  String _plantioPhaseChipLabel(_PlantioPhaseChip chip) => switch (chip) {
    _PlantioPhaseChip.validacaoPendente => 'Validação pendente',
    _PlantioPhaseChip.execucaoNaoAcompanhada => 'Execução não acompanhada',
    _PlantioPhaseChip.completo => 'Completo',
  };

  String _plantioSummaryLine(Color muted) {
    final cultivar = _cultivarCtrl.text.trim();
    final safra = _safraCtrl.text.trim();
    if (_dataPlantio != null) {
      final parts = <String>[
        if (cultivar.isNotEmpty) cultivar,
        if (safra.isNotEmpty) safra,
        if (occurrenceDapLabel(_dataPlantio) case final dap?) dap,
      ];
      if (parts.isNotEmpty) return parts.join(' · ');
    }
    if (_dataEmergencia != null) {
      final dae = occurrenceSoyAgeLabel(_dataEmergencia);
      final parts = <String>[
        'Emergência',
        if (dae != null) dae,
        if (cultivar.isNotEmpty) cultivar,
      ];
      return parts.join(' · ');
    }
    if (cultivar.isNotEmpty) return cultivar;
    if (safra.isNotEmpty) return safra;
    return 'Plantio';
  }

  void _focusEmergenciaPhase() {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    _patchForm(() {
      _plantioExecucaoExpanded = false;
      _plantioEmergenciaExpanded = true;
      _dataValidacao ??= normalized;
    });
  }

  bool _showAvaliacaoPlantioRow() {
    final exec = _hasPlantioExecucaoContent();
    final emerg = _hasPlantioEmergenciaContent();
    return exec && (!emerg || _dataPlantio != null);
  }

  Widget _buildPlantioAvaliacaoRow(
    Color color,
    Color idleSurface,
    Color idleBorder,
    Color idleText,
    List<(String, String)> avaliacoes, {
    required String? selected,
    required void Function(String? value) onChanged,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title, style: TextStyle(color: idleText, fontSize: 12)),
        ),
        Row(
          children: List.generate(avaliacoes.length, (i) {
            final label = avaliacoes[i].$1;
            final value = avaliacoes[i].$2;
            final sel = selected == value;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(sel ? null : value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: .2) : idleSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? color : idleBorder,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? color : idleText,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlantioSection(Color color) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = occurrenceFormIsIos(context);
    final muted = isIos ? v.subtitleColor : const Color(0xFF8E8E93);
    final idleSurface = v.cardBackground;
    final idleBorder = v.cardBorder;
    final idleText = v.onSheetSecondary;
    const avaliacoes = [('Boa', 'boa'), ('Ruim', 'ruim')];
    final chip = _plantioPhaseChip();

    return OccurrenceFlatFields(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_plantioSummaryLine(muted) != 'Plantio')
              Text(
                _plantioSummaryLine(muted),
                style: TextStyle(
                  color: idleText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if (chip != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    _plantioPhaseChipLabel(chip),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('occurrence_plantio_emergencia_shortcut'),
                onPressed: _focusEmergenciaPhase,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  'Acompanhar emergência',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: idleBorder)),
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  key: ValueKey(
                    'occurrence_plantio_execucao_tile_$_plantioExecucaoExpanded',
                  ),
                  initiallyExpanded: _plantioExecucaoExpanded,
                  onExpansionChanged: (expanded) =>
                      _patchForm(() => _plantioExecucaoExpanded = expanded),
                  title: Text(
                    'Execução',
                    style: TextStyle(
                      color: idleText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [
                    OccurrenceDarkField(
                      controller: _cultivarCtrl,
                      label: 'Cultivar',
                      hint: 'ex.: Intacta 2 IPRO, M6410 IPRO…',
                    ),
                    ..._buildCulturaSafraFields(),
                    const SizedBox(height: 10),
                    OccurrenceDateField(
                      key: const Key('occurrence_plantio_inicio_field'),
                      label: 'Início do plantio',
                      value: _dataPlantio,
                      helperText: occurrenceDapLabel(_dataPlantio),
                      onChanged: _setDataPlantio,
                    ),
                    const SizedBox(height: 10),
                    OccurrenceDateField(
                      key: const Key('occurrence_plantio_termino_field'),
                      label: 'Término do plantio',
                      value: _dataFimPlantio,
                      firstDate: _dataPlantio,
                      onChanged: (d) => _patchForm(() => _dataFimPlantio = d),
                    ),
                    const SizedBox(height: 10),
                    OccurrenceDarkField(
                      controller: _cicloDiasCtrl,
                      label: 'Ciclo (dias)',
                      hint: 'ex.: 115',
                    ),
                    if (occurrenceCicloLabel(
                          parseOccurrenceCicloDias(_cicloDiasCtrl.text),
                        )
                        case final cicloLabel?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          cicloLabel,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 10),
                    OccurrenceDarkField(
                      controller: _sementesPorMetroCtrl,
                      label: 'Sementes por metro',
                      hint: 'ex.: 14.5',
                    ),
                    if (_dataPlantio != null &&
                        !_plantioEmergenciaExpanded) ...[
                      const SizedBox(height: 10),
                      OccurrenceDarkField(
                        controller: _estandePlantasCtrl,
                        label: 'Estande (planejado)',
                        hint: 'ex.: 12',
                      ),
                    ],
                    if (_showAvaliacaoPlantioRow()) ...[
                      const SizedBox(height: 12),
                      _buildPlantioAvaliacaoRow(
                        color,
                        idleSurface,
                        idleBorder,
                        muted,
                        avaliacoes,
                        selected: _avaliacaoPlantio,
                        onChanged: (value) =>
                            _patchForm(() => _avaliacaoPlantio = value),
                        title: 'Avaliação do plantio',
                      ),
                    ],
                    const SizedBox(height: 10),
                    OccurrenceDarkField(
                      controller: _objetivoPlantioCtrl,
                      label: 'Objetivo',
                      hint: 'Objetivo do plantio…',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: idleBorder)),
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  key: ValueKey(
                    'occurrence_plantio_emergencia_tile_$_plantioEmergenciaExpanded',
                  ),
                  initiallyExpanded: _plantioEmergenciaExpanded,
                  onExpansionChanged: (expanded) =>
                      _patchForm(() => _plantioEmergenciaExpanded = expanded),
                  title: Text(
                    'Emergência',
                    style: TextStyle(
                      color: idleText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [
                    OccurrenceDateField(
                      key: const Key('occurrence_plantio_validacao_field'),
                      label: 'Data da validação',
                      value: _dataValidacao,
                      onChanged: (d) => _patchForm(() => _dataValidacao = d),
                    ),
                    const SizedBox(height: 10),
                    OccurrenceDateField(
                      key: const Key('occurrence_plantio_emergencia_field'),
                      label: 'Data de emergência',
                      value: _dataEmergencia,
                      helperText: occurrenceSoyAgeLabel(_dataEmergencia),
                      onChanged: (d) => _patchForm(() => _dataEmergencia = d),
                    ),
                    if (!_plantioExecucaoExpanded || _dataPlantio == null) ...[
                      const SizedBox(height: 10),
                      OccurrenceDarkField(
                        controller: _estandePlantasCtrl,
                        label: 'Estande observado',
                        hint: 'ex.: 12',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildPlantioAvaliacaoRow(
                      color,
                      idleSurface,
                      idleBorder,
                      muted,
                      avaliacoes,
                      selected: _avaliacaoEmergencia,
                      onChanged: (value) =>
                          _patchForm(() => _avaliacaoEmergencia = value),
                      title: 'Avaliação da emergência',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
