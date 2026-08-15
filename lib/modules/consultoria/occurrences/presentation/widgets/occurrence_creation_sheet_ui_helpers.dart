part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetLifecycle on _OccurrenceCreationSheetState {
  bool _hasUnsavedChanges() {
    if (_cultivarCtrl.text.trim().isNotEmpty) return true;
    if (_dataPlantio != null) return true;
    if (_estadio != null) return true;
    if (_selectedCategoryValue != null) return true;
    if (_descCtrl.text.trim().isNotEmpty) return true;
    if (_recomCtrl.text.trim().isNotEmpty) return true;
    if (_metrics.isNotEmpty) return true;
    if (_nutrientes.isNotEmpty) return true;
    if (_fotos.isNotEmpty) return true;
    if (_urgency != 'Média') return true;
    for (final controller in _notasCtrls.values) {
      if (controller.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> _handleCancel() async {
    HapticFeedback.lightImpact();
    await widget.onCancel?.call();
  }
}

extension _OccurrenceCreationSheetUiHelpers on _OccurrenceCreationSheetState {
  Widget _buildNutrientGrid(Color color) {
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
                color: sel
                    ? color.withValues(alpha: .25)
                    : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? color : Colors.white12,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sym,
                    style: TextStyle(
                      color: sel ? color : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    name.substring(0, name.length.clamp(0, 6)),
                    style: TextStyle(
                      color: sel ? color.withValues(alpha: .8) : Colors.white24,
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
    final current = _metricValue(OccurrenceCategory.agua, 'status');
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
                  color: sel
                      ? color.withValues(alpha: .2)
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? color : Colors.white12,
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
                        color: sel ? color : Colors.white38,
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

  int get _totalFotosCount =>
      _fotos.values.fold<int>(0, (sum, list) => sum + list.length);

  Future<void> _pickPhoto(OccurrenceCategory cat) async {
    await showSoloForteSheet<void>(
      context: context,
      preserveMaterialDefaults: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (sheetContext) => OccurrencePhotoSourceSheet(
        catEmoji: cat.emoji,
        catLabel: cat.label,
        onCamera: () {
          unawaited(
            _capturePhotoFromSource(sheetContext, cat, ImageSource.camera),
          );
        },
        onGallery: () {
          unawaited(
            _capturePhotoFromSource(sheetContext, cat, ImageSource.gallery),
          );
        },
      ),
    );
  }

  Future<void> _capturePhotoFromSource(
    BuildContext sheetContext,
    OccurrenceCategory cat,
    ImageSource source,
  ) async {
    Navigator.of(sheetContext).pop();
    if (!mounted) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (xFile == null || !mounted) return;

    final persisted = await ImageStorageService().persistLocalCopy(xFile.path);
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

  Future<void> _onAddPhotoPressed() async {
    if (_cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria antes de anexar foto.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    if (_cats.length == 1) {
      await _pickPhoto(_cats.first);
      return;
    }
    final cat = await showSoloForteSheet<OccurrenceCategory>(
      context: context,
      preserveMaterialDefaults: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => OccurrenceCatPickerSheet(cats: _cats.toList()),
    );
    if (cat != null) await _pickPhoto(cat);
  }

  Widget _buildPhotoActionSection() {
    final total = _totalFotosCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumTokens.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PremiumTokens.brandGreen.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OccurrenceSectionHeader(
            icon: '📷',
            title: 'Fotos da ocorrência',
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'Anexe foto para aparecer no relatório. Selecione a categoria e toque abaixo.'
                : '$total foto(s) pronta(s) para o relatório.',
            style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 12),
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in _fotos.entries)
                    for (final path in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _onAddPhotoPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: PremiumTokens.brandGreen,
                side: const BorderSide(
                  color: PremiumTokens.brandGreen,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: Text(
                total == 0 ? 'Tirar ou escolher foto' : 'Adicionar outra foto',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
