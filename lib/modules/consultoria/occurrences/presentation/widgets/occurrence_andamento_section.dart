import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/sync_status_contract.dart';
import '../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../domain/occurrence.dart';
import '../../domain/occurrence_andamento.dart';
import '../controllers/occurrence_controller.dart';

class OccurrenceAndamentoSection extends ConsumerStatefulWidget {
  final Occurrence occurrence;
  final bool readOnly;

  const OccurrenceAndamentoSection({
    super.key,
    required this.occurrence,
    this.readOnly = false,
  });

  @override
  ConsumerState<OccurrenceAndamentoSection> createState() =>
      _OccurrenceAndamentoSectionState();
}

class _OccurrenceAndamentoSectionState
    extends ConsumerState<OccurrenceAndamentoSection> {
  late OccurrenceAndamento _andamento;
  late TextEditingController _responsavelCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _andamento = widget.occurrence.andamentoEnum;
    _responsavelCtrl = TextEditingController(
      text: widget.occurrence.responsavelNome ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant OccurrenceAndamentoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrence.id != widget.occurrence.id) {
      _andamento = widget.occurrence.andamentoEnum;
      _responsavelCtrl.text = widget.occurrence.responsavelNome ?? '';
      return;
    }
    if (oldWidget.occurrence.andamento != widget.occurrence.andamento) {
      _andamento = widget.occurrence.andamentoEnum;
    }
    if (oldWidget.occurrence.responsavelNome !=
        widget.occurrence.responsavelNome) {
      _responsavelCtrl.text = widget.occurrence.responsavelNome ?? '';
    }
  }

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist({
    OccurrenceAndamento? andamento,
    String? responsavelNome,
    bool clearResponsavel = false,
  }) async {
    if (widget.readOnly || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(occurrenceRepositoryProvider);
      final next = widget.occurrence.copyWith(
        andamento: (andamento ?? _andamento).storageValue,
        responsavelNome: clearResponsavel
            ? null
            : (responsavelNome ?? _responsavelCtrl.text.trim()),
        clearResponsavelNome: clearResponsavel,
        syncStatus: SyncStatusContract.pendingSync,
        updatedAt: DateTime.now(),
      );
      await repo.updateOccurrence(next);
      ref.invalidate(occurrencesListProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onAndamentoSelected(OccurrenceAndamento value) async {
    if (value == _andamento) return;
    HapticFeedback.selectionClick();
    setState(() => _andamento = value);
    await _persist(andamento: value);
  }

  Future<void> _onResponsavelSubmitted() async {
    final trimmed = _responsavelCtrl.text.trim();
    final current = widget.occurrence.responsavelNome?.trim() ?? '';
    if (trimmed == current) return;
    await _persist(
      responsavelNome: trimmed.isEmpty ? null : trimmed,
      clearResponsavel: trimmed.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.occurrence.status == 'draft') {
      return const SizedBox.shrink();
    }

    final isIos = soloForteSheetIsIos(context);
    final cardBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF1C1C1E);
    final cardRadius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;
    final subtitle = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : Colors.white54;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(cardRadius),
          border: isIos
              ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Andamento',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: subtitle,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final step in OccurrenceAndamento.values)
                  _AndamentoChip(
                    label: step.label,
                    selected: _andamento == step,
                    color: occurrenceAndamentoChipColor(step),
                    readOnly: widget.readOnly,
                    onTap: () => _onAndamentoSelected(step),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Responsável',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: subtitle,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.readOnly)
              Text(
                (widget.occurrence.responsavelNome?.trim().isNotEmpty ?? false)
                    ? widget.occurrence.responsavelNome!.trim()
                    : 'Não informado',
                style: TextStyle(
                  fontSize: 15,
                  color: isIos ? CupertinoColors.label : Colors.white,
                ),
              )
            else
              TextField(
                controller: _responsavelCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Quem está cuidando?',
                  isDense: true,
                  filled: true,
                  fillColor: isIos
                      ? SoloForteSheetSkinIos.iconBackground
                      : const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _onResponsavelSubmitted(),
                onEditingComplete: _onResponsavelSubmitted,
              ),
            if (_saving) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _AndamentoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool readOnly;
  final VoidCallback onTap;

  const _AndamentoChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.readOnly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color.withValues(alpha: 0.18) : Colors.transparent;
    final border = selected ? color : color.withValues(alpha: 0.45);
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? color : border,
            ),
          ),
        ),
      ),
    );
  }
}
