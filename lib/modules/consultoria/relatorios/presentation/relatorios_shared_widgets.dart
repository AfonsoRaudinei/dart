part of 'relatorios_page.dart';

// ── Labels de ocorrência (sem snake_case) ────────────────────────────────────

String _occurrenceCategoryLabel(String? category) {
  return OccurrenceCategory.fromString(category).label;
}

String _occurrenceCategoryEmoji(String? category) {
  return OccurrenceCategory.fromString(category).emoji;
}

String _occurrenceUrgencyLabel(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'alta':
      return 'Alta';
    case 'baixa':
      return 'Baixa';
    case 'média':
    case 'media':
      return 'Média';
    default:
      if (type == null || type.trim().isEmpty) return 'Média';
      // Já legível (ex.: "Média") ou legado
      if (!type.contains('_')) return type;
      return _occurrenceCategoryLabel(type);
  }
}

String _occurrenceCardTitle(Occurrence occurrence) {
  final category = occurrence.category;
  if (category != null && category.trim().isNotEmpty) {
    return '${_occurrenceCategoryEmoji(category)} ${_occurrenceCategoryLabel(category)}';
  }
  // type pode ser urgência OU categoria legada
  final asCategory = OccurrenceCategory.fromString(occurrence.type);
  if (occurrence.type.contains('_') ||
      asCategory != OccurrenceCategory.doenca ||
      occurrence.type.toLowerCase() == 'doenca' ||
      occurrence.type.toLowerCase() == 'doença') {
    return '${asCategory.emoji} ${asCategory.label}';
  }
  return _occurrenceUrgencyLabel(occurrence.type);
}

String? _occurrenceCardSubtitle(Occurrence occurrence) {
  final urgency = _occurrenceUrgencyLabel(occurrence.type);
  final category = occurrence.category;
  if (category != null && category.trim().isNotEmpty) {
    return 'Urgência: $urgency';
  }
  return null;
}

// ── Menu assíncrono ──────────────────────────────────────────────────────────

class _AsyncActionMenu extends StatefulWidget {
  final String tooltip;
  final List<PopupMenuEntry<String>> Function(BuildContext context) itemBuilder;
  final Future<void> Function(String value) onSelected;

  const _AsyncActionMenu({
    required this.tooltip,
    required this.itemBuilder,
    required this.onSelected,
  });

  @override
  State<_AsyncActionMenu> createState() => _AsyncActionMenuState();
}

class _AsyncActionMenuState extends State<_AsyncActionMenu> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox.square(
        dimension: 40,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return PopupMenuButton<String>(
      tooltip: widget.tooltip,
      itemBuilder: widget.itemBuilder,
      onSelected: _run,
    );
  }

  Future<void> _run(String value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSelected(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingError(e, action: 'Erro na ação'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ── Segmented header ─────────────────────────────────────────────────────────

enum _RelatoriosSegment { visitas, ocorrencias, gerados, midia }

class _RelatoriosSegmentBar extends StatelessWidget {
  final _RelatoriosSegment selected;
  final ValueChanged<_RelatoriosSegment> onSelected;

  const _RelatoriosSegmentBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _seg('Visitas', _RelatoriosSegment.visitas),
          _seg('Ocorrências', _RelatoriosSegment.ocorrencias),
          _seg('Gerados', _RelatoriosSegment.gerados),
          _seg('Mídia', _RelatoriosSegment.midia),
        ],
      ),
    );
  }

  Widget _seg(String label, _RelatoriosSegment value) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: isSelected
                  ? PremiumTokens.textPrimaryLight
                  : PremiumTokens.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty / loading / error ──────────────────────────────────────────────────

class _PremiumEmptyState extends StatelessWidget {
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const _PremiumEmptyState({
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: PremiumTokens.textSecondaryLight,
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onCta,
              child: Text(
                ctaLabel!,
                style: const TextStyle(
                  color: PremiumTokens.brandGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  final String title;
  const _SectionLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: PremiumTokens.textPrimaryLight,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;
  const _SectionError({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: PremiumTokens.textPrimaryLight,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Erro ao carregar dados',
                  style: TextStyle(
                    fontSize: 13,
                    color: PremiumTokens.alertError,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Card Premium (inset grouped) ─────────────────────────────────────────────

class _DataCard extends StatelessWidget {
  final Widget? leading;
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DataCard({
    this.leading,
    this.eyebrow,
    required this.title,
    this.subtitle,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: PremiumTokens.surfaceLight,
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusSm),
        boxShadow: PremiumTokens.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: leading!,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: PremiumTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: PremiumTokens.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PremiumTokens.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: PremiumTokens.textSecondaryLight.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 2), trailing!],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class _InsetGroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const _InsetGroupHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: PremiumTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PremiumTokens.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
