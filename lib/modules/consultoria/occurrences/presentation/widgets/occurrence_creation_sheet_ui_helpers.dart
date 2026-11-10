part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetLifecycle on _OccurrenceCreationSheetState {
  bool _hasUnsavedChanges() {
    if (_cultivarCtrl.text.trim().isNotEmpty) return true;
    if (_culturaCtrl.text.trim().isNotEmpty) return true;
    if (_safraCtrl.text.trim().isNotEmpty) return true;
    if (_dataPlantio != null) return true;
    if (_dataEmergencia != null) return true;
    if (_dataFimPlantio != null) return true;
    if (_cicloDiasCtrl.text.trim().isNotEmpty) return true;
    if (_sementesPorMetroCtrl.text.trim().isNotEmpty) return true;
    if (_estandePlantasCtrl.text.trim().isNotEmpty) return true;
    if (_avaliacaoPlantio != null) return true;
    if (_objetivoPlantioCtrl.text.trim().isNotEmpty) return true;
    if (_amostraCodigoCtrl.text.trim().isNotEmpty) return true;
    if (_amostraColetorCtrl.text.trim().isNotEmpty) return true;
    if (_amostraLaudoCtrl.text.trim().isNotEmpty) return true;
    if (_amostraTramite != null &&
        _amostraTramite != OccurrenceAmostraTramite.coletada) {
      return true;
    }
    if (_estadio != null && !_estadioSugerido) return true;
    if (_selectedCategoryValue != null) return true;
    if (_descCtrl.text.trim().isNotEmpty) return true;
    if (_ordem.hasText) return true;
    if (_metrics.isNotEmpty) return true;
    if (_nutrientes.isNotEmpty) return true;
    if (_fotos.isNotEmpty) return true;
    if (_audioPath?.trim().isNotEmpty == true) return true;
    if (_urgency != 'Média') return true;
    for (final controller in _notasCtrls.values) {
      if (controller.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  void _setDataPlantio(DateTime? inicio) => _patchForm(() {
    _dataPlantio = inicio;
    if (_terminoAntesDoInicio(inicio, _dataFimPlantio)) _dataFimPlantio = null;
    if (_isPlantio && inicio != null && _safraCtrl.text.trim().isEmpty) {
      _safraCtrl.text = safraFromPlantio(inicio) ?? '';
    }
  });

  Future<void> _handleCancel() async {
    HapticFeedback.lightImpact();
    await widget.onCancel?.call();
  }
}

extension _OccurrenceCreationSheetUiHelpers on _OccurrenceCreationSheetState {
  Widget _buildNutrientGrid(Color color) {
    final v = SoloForteSheetVisuals.of(context);
    final idleSurface = v.cardBackground;
    final idleBorder = v.chipBorderInactive;
    final idleText = v.chipTextInactive;
    final idleSub = v.chipTextInactive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kNutrientes.map((entry) {
          final sym = entry.$1;
          final name = entry.$2;
          final sel = _nutrientes.contains(sym);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _toggleNutriente(sym, sel);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: .25) : idleSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? color : idleBorder,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sym,
                    style: TextStyle(
                      color: sel ? color : idleText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    name.substring(0, name.length.clamp(0, 6)),
                    style: TextStyle(
                      color: sel ? color.withValues(alpha: .8) : idleSub,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAguaSection(Color color) {
    final v = SoloForteSheetVisuals.of(context);
    final current = _metricValue(OccurrenceCategory.agua, 'status');
    final idleSurface = v.cardBackground;
    final idleBorder = v.cardBorder;
    final idleText = v.onSheetSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: List.generate(kAguaLabels.length, (i) {
          final sel = current == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setMetric(OccurrenceCategory.agua, 'status', i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: .2) : idleSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? color : idleBorder,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      i == 0
                          ? '💧'
                          : i == 1
                          ? '🏜'
                          : '🌊',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kAguaLabels[i],
                      style: TextStyle(
                        color: sel ? color : idleText,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAmostraSection(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: OccurrenceAmostraSoloSection(
        codigoController: _amostraCodigoCtrl,
        coletorController: _amostraColetorCtrl,
        laudoController: _amostraLaudoCtrl,
        tramite: _amostraTramite,
        onTramiteChanged: (step) => _patchForm(() => _amostraTramite = step),
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          OccurrenceDateField(
            key: const Key('occurrence_plantio_emergencia_field'),
            label: 'Data de emergência',
            value: _dataEmergencia,
            helperText: occurrenceSoyAgeLabel(_dataEmergencia),
            onChanged: (d) => _patchForm(() => _dataEmergencia = d),
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
          const SizedBox(height: 10),
          OccurrenceDarkField(
            controller: _estandePlantasCtrl,
            label: 'Estande de plantas',
            hint: 'ex.: 12',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Avaliação do plantio',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          Row(
            children: List.generate(avaliacoes.length, (i) {
              final label = avaliacoes[i].$1;
              final value = avaliacoes[i].$2;
              final sel = _avaliacaoPlantio == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _patchForm(() {
                      _avaliacaoPlantio = sel ? null : value;
                    });
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
          const SizedBox(height: 10),
          OccurrenceDarkField(
            controller: _objetivoPlantioCtrl,
            label: 'Objetivo',
            hint: 'Objetivo do plantio…',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  int get _totalFotosCount =>
      _fotos.values.fold<int>(0, (sum, list) => sum + list.length);

  List<String> _flatFotoPaths() {
    final paths = <String>[];
    for (final entry in _fotos.entries) {
      paths.addAll(entry.value);
    }
    return paths;
  }

  void _removeFlatPhoto(int flatIndex) {
    var cursor = 0;
    for (final entry in _fotos.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        if (cursor == flatIndex) {
          final path = entry.value[i];
          _patchForm(() {
            entry.value.removeAt(i);
            _dropCaptionIfOrphan(path);
          });
          return;
        }
        cursor++;
      }
    }
  }

  Future<OccurrenceCategory?> _resolveCategoryForPhoto() async {
    if (_cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria antes de anexar foto.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }
    if (_cats.length == 1) return _cats.first;
    return showSoloForteSheet<OccurrenceCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => OccurrenceCatPickerSheet(cats: _cats.toList()),
    );
  }

  Future<void> _onPhotoOriginSelected(SoloFortePhotoPickerOrigin origin) async {
    HapticFeedback.selectionClick();
    final cat = await _resolveCategoryForPhoto();
    if (cat == null || !mounted) return;

    final rawPath = await resolveSoloFortePhotoPath(origin);
    if (rawPath == null || !mounted) return;

    final persisted = await ImageStorageService().persistLocalCopy(rawPath);
    if (persisted == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a foto. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _registerPersistedPhoto(cat, persisted);
  }

  Widget _buildPhotoActionSection() {
    final v = SoloForteSheetVisuals.of(context);
    final total = _totalFotosCount;
    final isIos = occurrenceFormIsIos(context);
    final accent = isIos ? v.iconStroke : context.themeAccent;
    final hint = isIos ? v.subtitleColor : const Color(0xFFAEAEB2);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(v.cardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OccurrenceSectionHeader(
            title: 'Fotos da ocorrência',
          ),
          const SizedBox(height: 6),
          OccurrencePhotoStatusText(
            paths: _flatFotoPaths(),
            emptyHint:
                'Anexe foto para aparecer no relatório. Selecione a categoria e toque em um ícone abaixo.',
            hintColor: hint,
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            OccurrencePhotoGallery(
              paths: _flatFotoPaths(),
              captions: Map<String, String>.from(_photoCaptions),
              thumbnailSize: 56,
              readOnly: false,
              onRemove: _removeFlatPhoto,
              onCaptionChanged: (index, caption) {
                final paths = _flatFotoPaths();
                if (index < 0 || index >= paths.length) return;
                _setPhotoCaption(paths[index], caption);
              },
            ),
          ],
          const SizedBox(height: 12),
          OccurrencePhotoOriginToolbar(
            accent: accent,
            onOriginSelected: (origin) {
              unawaited(_onPhotoOriginSelected(origin));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(OccurrenceCategory cat) {
    final color = _catColor(cat);
    final metrics = categoryMetrics(cat.name);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (cat == OccurrenceCategory.nutricional)
              _buildNutrientGrid(color)
            else if (cat == OccurrenceCategory.agua)
              _buildAguaSection(color)
            else if (cat == OccurrenceCategory.plantio)
              _buildPlantioSection(color)
            else if (cat == OccurrenceCategory.amostraSolo)
              _buildAmostraSection(color)
            else
              ...metrics.map(
                (metric) => OccurrenceSliderRow(
                  label: metricLabel(metric),
                  value: _metricValue(cat, metric),
                  color: color,
                  onChanged: (v) => _setMetric(cat, metric, v),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: OccurrenceDarkField(
                controller: _notaCtrl(cat.name),
                label: 'Notas (${cat.label})',
                hint: 'Observações específicas…',
                maxLines: 2,
              ),
            ),
            if (_fotos[cat.name]?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: OccurrencePhotoGallery(
                  paths: List<String>.from(_fotos[cat.name]!),
                  captions: Map<String, String>.from(_photoCaptions),
                  thumbnailSize: 72,
                  readOnly: false,
                  onRemove: (index) => _patchForm(() {
                    final list = _fotos[cat.name]!;
                    if (index < 0 || index >= list.length) return;
                    final path = list.removeAt(index);
                    _dropCaptionIfOrphan(path);
                  }),
                  onCaptionChanged: (index, caption) {
                    final list = _fotos[cat.name];
                    if (list == null || index < 0 || index >= list.length) {
                      return;
                    }
                    _setPhotoCaption(list[index], caption);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension _OccurrenceCreationSheetAreaVisitadaUi
    on _OccurrenceCreationSheetState {
  String get _primarySaveButtonLabel {
    if (widget.initialOccurrence != null) return 'Salvar Alterações';
    if (_isAreaVisitada) return 'Salvar localização';
    return 'Salvar';
  }

  Widget _compactMapHeader({required Color muted, required Color titleColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isAreaVisitada)
                Text(
                  'Área visitada',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                )
              else
                Text(
                  'Ponto definido no mapa',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              if (_isAreaVisitada) ...[
                const SizedBox(height: 2),
                Text(
                  'Ponto marcado no mapa',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        if (widget.onCancel != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCancel,
            color: muted,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

extension _OccurrenceCreationSheetFormSections
    on _OccurrenceCreationSheetState {
  Widget _buildFormHeader({
    required Color accent,
    required Color muted,
    required Color titleColor,
  }) {
    if (widget.compactHeader && widget.initialOccurrence == null) {
      return _compactMapHeader(muted: muted, titleColor: titleColor);
    }
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent, width: .6),
          ),
          child: Icon(Icons.location_on_rounded, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialOccurrence == null
                    ? (_isAreaVisitada ? 'Área Visitada' : 'Nova Ocorrência')
                    : 'Editar Ocorrência',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Ponto definido no mapa',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (widget.onCancel != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCancel,
            color: muted,
          ),
      ],
    );
  }

  /// Criação: talhão do prefill (ou o que contém o pin). Edição: talhão
  /// já vinculado (ou o que contém o pin).
  OccurrenceLocationQuery get _locationQuery {
    final occurrence = widget.initialOccurrence;
    final prefill = occurrence == null ? widget.talhaoPrefill : null;
    return (
      fieldId: occurrence?.fieldId ?? prefill?.fieldId,
      fazendaId: prefill?.fazendaId,
      talhaoNome: prefill?.talhaoNome,
      lat: _pinLatitude,
      lng: _pinLongitude,
    );
  }

  Widget _buildLocationLine(Color muted) {
    final location = ref
        .watch(occurrenceLocationProvider(_locationQuery))
        .valueOrNull;
    if (location == null) return const SizedBox.shrink();
    return Padding(
      key: const Key('occurrence_location_line'),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 14, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location.display,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCultivarPlantioBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OccurrenceSectionHeader(title: 'Cultivar & Plantio'),
        const SizedBox(height: 10),
        OccurrenceDarkField(
          controller: _cultivarCtrl,
          label: 'Cultivar (opcional)',
          hint: 'ex.: Intacta 2 IPRO, M6410 IPRO…',
        ),
        const SizedBox(height: 10),
        OccurrenceDateField(
          label: 'Data de plantio',
          value: _dataPlantio,
          helperText: occurrenceDapLabel(_dataPlantio),
          onChanged: _setDataPlantio,
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final v = SoloForteSheetVisuals.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _categories.map((cat) {
        final isSelected = _selectedCategoryValue == cat.value;
        final selectedColor =
            cat.enumValue?.markerColor ?? const Color(0xFF795548);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _patchForm(() {
              _selectedCategoryValue = cat.value;
              _cats.clear();
              if (cat.enumValue != null) {
                _cats.add(cat.enumValue!);
              }
              if (cat.value == kOccurrenceAreaVisitadaCategory) {
                _selectedClient = null;
              }
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.2)
                      : v.cardBackground,
                  border: isSelected
                      ? Border.all(color: selectedColor, width: 2)
                      : (v.isDark ? null : Border.all(color: v.cardBorder)),
                ),
                child: Icon(
                  cat.icon,
                  size: 22,
                  color: isSelected ? selectedColor : v.subtitleColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 64,
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? selectedColor : v.subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencySelector() {
    final v = SoloForteSheetVisuals.of(context);
    return Row(
      children: ['Baixa', 'Média', 'Alta'].map((u) {
        final sel = _urgency == u;
        final color = u == 'Baixa'
            ? const Color(0xFFFFCC00)
            : u == 'Média'
            ? const Color(0xFFFF9500)
            : const Color(0xFFFF3B30);
        return Expanded(
          child: GestureDetector(
            onTap: () => _patchForm(() => _urgency = u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: .18) : v.cardBackground,
                borderRadius: BorderRadius.circular(v.cardRadius),
                border: Border.all(
                  color: sel ? color : v.chipBorderInactive,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  u,
                  style: TextStyle(
                    color: sel ? color : v.chipTextInactive,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
