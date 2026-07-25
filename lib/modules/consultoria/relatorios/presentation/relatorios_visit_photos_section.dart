part of 'relatorios_page.dart';

enum _VisitPhotoFilter { all, normal, vegetal, orphan }

List<QuickPhotoRecord> _filterVisitPhotos(
  List<QuickPhotoRecord> photos,
  _VisitPhotoFilter filter,
) {
  switch (filter) {
    case _VisitPhotoFilter.normal:
      return photos
          .where((photo) => photo.type == QuickPhotoType.normal.value)
          .toList();
    case _VisitPhotoFilter.vegetal:
      return photos
          .where((photo) => photo.type == QuickPhotoType.vegetalFilter.value)
          .toList();
    case _VisitPhotoFilter.orphan:
      return photos
          .where((photo) => photo.visitSessionId?.isNotEmpty != true)
          .toList();
    case _VisitPhotoFilter.all:
      return photos;
  }
}

class _VisitPhotosSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;

  const _VisitPhotosSection({required this.dateFormat});

  @override
  ConsumerState<_VisitPhotosSection> createState() =>
      _VisitPhotosSectionState();
}

class _VisitPhotosSectionState extends ConsumerState<_VisitPhotosSection> {
  _VisitPhotoFilter _filter = _VisitPhotoFilter.all;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(quickPhotoListProvider);

    return photosAsync.when(
      data: (photos) {
        final filtered = _filterVisitPhotos(photos, _filter);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: 3 + (filtered.isEmpty ? 1 : filtered.length),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _InsetGroupHeader(
                title: 'Fotos da visita',
                count: filtered.length,
              );
            }
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VisitPhotoFilterBar(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
              );
            }
            if (filtered.isEmpty) {
              if (index == 2) {
                return _PremiumEmptyState(
                  message: photos.isEmpty
                      ? _emptyMessage(_VisitPhotoFilter.all)
                      : _emptyMessage(_filter),
                  ctaLabel: 'Abrir mapa',
                  onCta: () => context.go(AppRoutes.map),
                );
              }
              return const SizedBox(height: kFabSafeArea);
            }
            if (index == filtered.length + 2) {
              return const SizedBox(height: kFabSafeArea);
            }
            final photo = filtered[index - 2];
            return _VisitPhotoCard(
              photo: photo,
              dateFormat: widget.dateFormat,
              onTap: () => _openPreview(context, photo),
              onAction: (value) => _handleAction(context, photo, value),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: _SectionLoading(title: 'Fotos da visita'),
      ),
      error: (error, stack) {
        AppLogger.error(
          'quickPhotoListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: error,
          stackTrace: stack,
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _SectionError(
            title: 'Fotos da visita',
            onRetry: () => ref.invalidate(quickPhotoListProvider),
          ),
        );
      },
    );
  }

  String _emptyMessage(_VisitPhotoFilter filter) {
    switch (filter) {
      case _VisitPhotoFilter.normal:
        return 'Nenhuma foto rápida registrada.';
      case _VisitPhotoFilter.vegetal:
        return 'Nenhuma foto de inversão vegetal registrada.';
      case _VisitPhotoFilter.orphan:
        return 'Nenhuma foto órfã (sem visita vinculada).';
      case _VisitPhotoFilter.all:
        return 'Nenhuma foto registrada. Use o botão + no mapa.';
    }
  }

  Future<bool> _fileExists(QuickPhotoRecord photo) async {
    final path = photo.imagePath;
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }

  Future<void> _handleAction(
    BuildContext context,
    QuickPhotoRecord photo,
    String value,
  ) async {
    switch (value) {
      case 'preview':
        await _openPreview(context, photo);
        return;
      case 'edit':
        await _openEditor(context, photo);
        return;
      case 'map':
        _openOnMap(context, photo);
        return;
      case 'delete':
        await _confirmDelete(context, photo);
        return;
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    QuickPhotoRecord photo,
  ) async {
    final path = photo.imagePath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Arquivo da foto não encontrado. Exclua a mídia órfã ou capture outra.',
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final saved = await QuickPhotoFlow.openExisting(
      context,
      photoId: photo.id,
      imagePath: path,
      lat: photo.latitude,
      lng: photo.longitude,
      visitSessionId: photo.visitSessionId,
      initialFilterActive: photo.type == QuickPhotoType.vegetalFilter.value,
    );
    if (!context.mounted) return;
    if (saved) {
      ref.invalidate(quickPhotoListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mídia atualizada.')),
      );
    }
  }

  void _openOnMap(BuildContext context, QuickPhotoRecord photo) {
    final lat = photo.latitude;
    final lng = photo.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta mídia não tem coordenadas.')),
      );
      return;
    }
    if (!lat.isFinite || !lng.isFinite || (lat == 0 && lng == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas da mídia inválidas.')),
      );
      return;
    }
    context.go(
      '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
      '&lng=${lng.toStringAsFixed(6)}',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    QuickPhotoRecord photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir mídia?'),
        content: Text(
          photo.visitSessionId?.isNotEmpty == true
              ? 'A foto será removida da lista e marcada como excluída.'
              : 'Mídia órfã (sem visita). Será removida da lista mesmo sem arquivo local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(quickPhotoRepositoryProvider).softDelete(photo.id);
    ref.invalidate(quickPhotoListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mídia excluída.')),
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    QuickPhotoRecord photo,
  ) async {
    final path = photo.imagePath;
    final hasFile = await _fileExists(photo);

    if (!context.mounted) return;

    if (!hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo da foto não encontrado.')),
      );
      await _confirmDelete(context, photo);
      return;
    }

    final file = File(path!);
    final isVegetal = photo.type == QuickPhotoType.vegetalFilter.value;
    await showSoloForteSheet<void>(
      context: context,
      maxHeightFraction: 0.88,
      builder: (sheetContext) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          QuickPhotoRepository.typeLabel(photo.type),
                          style: const TextStyle(
                            fontSize: SoloForteSheetTokens.titleFontSize,
                            fontWeight: SoloForteSheetTokens.titleWeight,
                            color: SoloForteSheetTokens.titleColor,
                          ),
                        ),
                        if (isVegetal)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Inversão vegetal aplicada no arquivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFAEAEB2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        color: PremiumTokens.brandGreenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SoloForteSheetTokens.divider),
            Expanded(
              child: InteractiveViewer(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (photo.latitude != null && photo.longitude != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _openOnMap(context, photo);
                        },
                        child: const Text('Ver no mapa'),
                      ),
                    ),
                  if (photo.latitude != null && photo.longitude != null)
                    const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await _confirmDelete(context, photo);
                      },
                      child: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitPhotoFilterBar extends StatelessWidget {
  final _VisitPhotoFilter selected;
  final ValueChanged<_VisitPhotoFilter> onSelected;

  const _VisitPhotoFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _filterChip(context, 'Todas', _VisitPhotoFilter.all),
        _filterChip(context, 'Foto rápida', _VisitPhotoFilter.normal),
        _filterChip(context, 'Inversão vegetal', _VisitPhotoFilter.vegetal),
        _filterChip(context, 'Órfãs', _VisitPhotoFilter.orphan),
      ],
    );
  }

  Widget _filterChip(BuildContext context, String label, _VisitPhotoFilter value) {
    final isSelected = selected == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTokens.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PremiumTokens.brandGreen
                : const Color(0xFFD1D1D6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.premiumTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _VisitPhotoCard extends StatelessWidget {
  final QuickPhotoRecord photo;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final Future<void> Function(String value) onAction;

  const _VisitPhotoCard({
    required this.photo,
    required this.dateFormat,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final linked = photo.visitSessionId?.isNotEmpty == true;
    final path = photo.imagePath;
    final isVegetal = photo.type == QuickPhotoType.vegetalFilter.value;
    final hasCoords = photo.latitude != null && photo.longitude != null;

    return _DataCard(
      leading: _VisitPhotoThumbnail(path: path, isVegetal: isVegetal),
      eyebrow: isVegetal ? 'Inversão vegetal' : 'Foto rápida',
      title: QuickPhotoRepository.typeLabel(photo.type),
      subtitle: linked
          ? 'Visita ${RelatorioHtmlRenderer.shortId(photo.visitSessionId!)}'
          : 'Sem visita vinculada',
      date: dateFormat.format(photo.createdAt.toLocal()),
      statusLabel: linked ? 'Vinculada' : 'Órfã',
      statusColor: linked ? PremiumTokens.brandGreen : const Color(0xFFFF9500),
      onTap: onTap,
      trailing: _AsyncActionMenu(
        tooltip: 'Ações da mídia',
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'preview',
            child: Text('Pré-visualizar'),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Text('Editar'),
          ),
          if (hasCoords)
            const PopupMenuItem(
              value: 'map',
              child: Text('Ver no mapa'),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: onAction,
      ),
    );
  }
}

class _VisitPhotoThumbnail extends StatelessWidget {
  final String? path;
  final bool isVegetal;

  const _VisitPhotoThumbnail({required this.path, required this.isVegetal});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (48 * dpr).round();

    Widget image;
    if (path == null || path!.isEmpty) {
      image = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        color: const Color(0xFFE5E5EA),
        child: Text(
          'Sem\narq.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: context.premiumTextSecondary),
        ),
      );
    } else {
      final file = File(path!);
      image = Image.file(
        file,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          color: const Color(0xFFE5E5EA),
          child: Text(
            'Indisp.',
            style: TextStyle(
              fontSize: 9,
              color: context.premiumTextSecondary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image,
          ),
          if (isVegetal)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 1),
                color: Colors.black.withValues(alpha: 0.55),
                child: const Text(
                  'Inversão',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
