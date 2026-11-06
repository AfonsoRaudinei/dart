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
  late FocusNode _responsavelFocus;
  String? _savedResponsavel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _andamento = widget.occurrence.andamentoEnum;
    _responsavelCtrl = TextEditingController(
      text: widget.occurrence.responsavelNome ?? '',
    );
    _savedResponsavel = _normalizedResponsavel(
      widget.occurrence.responsavelNome,
    );
    _responsavelFocus = FocusNode()..addListener(_onResponsavelFocusChange);
  }

  @override
  void didUpdateWidget(covariant OccurrenceAndamentoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrence.id != widget.occurrence.id) {
      _andamento = widget.occurrence.andamentoEnum;
      _savedResponsavel = _normalizedResponsavel(
        widget.occurrence.responsavelNome,
      );
      _responsavelCtrl.text = widget.occurrence.responsavelNome ?? '';
      return;
    }
    if (oldWidget.occurrence.andamento != widget.occurrence.andamento) {
      _andamento = widget.occurrence.andamentoEnum;
    }
    if (oldWidget.occurrence.responsavelNome !=
        widget.occurrence.responsavelNome) {
      _savedResponsavel = _normalizedResponsavel(
        widget.occurrence.responsavelNome,
      );
      // Não sobrescrever o que o usuário está digitando.
      if (!_responsavelFocus.hasFocus) {
        _responsavelCtrl.text = widget.occurrence.responsavelNome ?? '';
      }
    }
  }

  @override
  void dispose() {
    // Sem persistência aqui: o widget já saiu da árvore e `ref` não é seguro.
    _responsavelFocus
      ..removeListener(_onResponsavelFocusChange)
      ..dispose();
    _responsavelCtrl.dispose();
    super.dispose();
  }

  void _onResponsavelFocusChange() {
    if (!mounted || _responsavelFocus.hasFocus) return;
    _onResponsavelSubmitted();
  }

  static String? _normalizedResponsavel(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _persist({
    required OccurrenceAndamento andamento,
    required String? responsavelNome,
  }) async {
    if (widget.readOnly || _saving) return false;
    setState(() => _saving = true);
    try {
      final repo = ref.read(occurrenceRepositoryProvider);
      final saved = await updateLiveOccurrence(
        repo,
        widget.occurrence,
        (live) => live.copyWith(
          andamento: andamento.storageValue,
          responsavelNome: responsavelNome,
          clearResponsavelNome: responsavelNome == null,
          syncStatus: SyncStatusContract.pendingSync,
          updatedAt: DateTime.now(),
        ),
      );
      if (!saved) return false;
      _savedResponsavel = responsavelNome;
      ref.invalidate(occurrencesListProvider);
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onAndamentoSelected(OccurrenceAndamento value) async {
    if (value == _andamento || _saving) return;
    HapticFeedback.selectionClick();
    final previous = _andamento;
    setState(() => _andamento = value);
    final saved = await _persist(
      andamento: value,
      responsavelNome: _savedResponsavel,
    );
    if (!saved && mounted) setState(() => _andamento = previous);
  }

  Future<void> _onResponsavelSubmitted() async {
    final typed = _normalizedResponsavel(_responsavelCtrl.text);
    if (typed == _savedResponsavel) return;
    await _persist(andamento: _andamento, responsavelNome: typed);
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
                focusNode: _responsavelFocus,
                // Persistência acontece no blur (_onResponsavelFocusChange).
                onEditingComplete: _responsavelFocus.unfocus,
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
