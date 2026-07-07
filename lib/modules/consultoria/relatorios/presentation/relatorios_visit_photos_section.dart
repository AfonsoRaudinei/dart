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
        return _SectionContainer(
          title: 'Fotos da visita',
          count: filtered.length,
          emptyMessage: _emptyMessage(_filter),
          isEmpty: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VisitPhotoFilterBar(
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 8),
              if (photos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _emptyMessage(_VisitPhotoFilter.all),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _emptyMessage(_filter),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...filtered.map(
                  (photo) => _VisitPhotoCard(
                    photo: photo,
                    dateFormat: widget.dateFormat,
                    onTap: () => _openPreview(context, photo),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const _SectionLoading(title: 'Fotos da visita'),
      error: (error, stack) {
        debugPrint(
          '[RelatoriosScreen] quickPhotoListProvider ERROR: $error\n$stack',
        );
        return _SectionError(
          title: 'Fotos da visita',
          onRetry: () => ref.invalidate(quickPhotoListProvider),
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

  Future<void> _openPreview(BuildContext context, QuickPhotoRecord photo) async {
    final path = photo.imagePath;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo da foto não encontrado.')),
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      QuickPhotoRepository.typeLabel(photo.type),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
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
      runSpacing: 4,
      children: [
        _filterChip('Todas', _VisitPhotoFilter.all),
        _filterChip('Foto rápida', _VisitPhotoFilter.normal),
        _filterChip('Inversão vegetal', _VisitPhotoFilter.vegetal),
        _filterChip('Órfãs', _VisitPhotoFilter.orphan),
      ],
    );
  }

  Widget _filterChip(String label, _VisitPhotoFilter value) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _VisitPhotoCard extends StatelessWidget {
  final QuickPhotoRecord photo;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _VisitPhotoCard({
    required this.photo,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final linked = photo.visitSessionId?.isNotEmpty == true;
    final path = photo.imagePath;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: _VisitPhotoThumbnail(path: path),
        title: QuickPhotoRepository.typeLabel(photo.type),
        subtitle: linked
            ? 'Visita ${RelatorioHtmlRenderer.shortId(photo.visitSessionId!)}'
            : 'Sem visita vinculada',
        date: dateFormat.format(photo.createdAt.toLocal()),
        statusLabel: linked ? 'Vinculada' : 'Órfã',
        statusColor: linked ? const Color(0xFF34C759) : const Color(0xFFFF9500),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _VisitPhotoThumbnail extends StatelessWidget {
  final String? path;

  const _VisitPhotoThumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, size: 20);
    }

    final file = File(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, size: 20),
      ),
    );
  }
}
