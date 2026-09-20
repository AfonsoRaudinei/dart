import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_form_padding.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_linked_field_list.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

class TalhaoUnionCandidate {
  const TalhaoUnionCandidate({
    required this.id,
    required this.name,
    required this.areaHa,
  });

  final String id;
  final String name;
  final double areaHa;
}

Future<bool> showTalhaoUnionSheet(
  BuildContext context, {
  required String clientId,
  String? farmId,
  required String primaryFieldId,
  required String primaryFieldName,
  required List<TalhaoUnionCandidate> candidates,
}) async {
  if (candidates.isEmpty) return false;

  final saved = await showSoloForteSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => TalhaoUnionSheet(
      clientId: clientId,
      farmId: farmId,
      primaryFieldId: primaryFieldId,
      primaryFieldName: primaryFieldName,
      candidates: candidates,
    ),
  );

  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Talhões combinados com sucesso.')),
    );
  }

  return saved == true;
}

class TalhaoUnionSheet extends ConsumerStatefulWidget {
  const TalhaoUnionSheet({
    super.key,
    required this.clientId,
    this.farmId,
    required this.primaryFieldId,
    required this.primaryFieldName,
    required this.candidates,
  });

  final String clientId;
  final String? farmId;
  final String primaryFieldId;
  final String primaryFieldName;
  final List<TalhaoUnionCandidate> candidates;

  @override
  ConsumerState<TalhaoUnionSheet> createState() => _TalhaoUnionSheetState();
}

class _TalhaoUnionSheetState extends ConsumerState<TalhaoUnionSheet> {
  String? _selectedFieldId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.candidates.length == 1) {
      _selectedFieldId = widget.candidates.first.id;
    }
  }

  Future<void> _submit() async {
    final secondaryFieldId = _selectedFieldId;
    if (_isSaving || secondaryFieldId == null) return;

    setState(() => _isSaving = true);
    try {
      final writer = ref.read(iDrawingFieldWriterProvider);
      await writer.unionDrawingFields(
        primaryFieldId: widget.primaryFieldId,
        secondaryFieldId: secondaryFieldId,
        clientId: widget.clientId,
      );

      ref.invalidate(clientDetailProvider(widget.clientId));
      ref.invalidate(clientDrawingFieldsProvider(widget.clientId));
      if (widget.farmId != null && widget.farmId!.isNotEmpty) {
        ref.invalidate(farmLinkedFieldsProvider(widget.farmId!));
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Não foi possível combinar os talhões'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : null;
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final sheetBg = isIos ? Colors.transparent : Colors.white;
    final sheetRadius = isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : PremiumTokens.brandGreen;
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      child: Padding(
        padding: clientSheetFormPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'União',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Combinar com outra área',
              style: TextStyle(color: muted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Talhão principal: ${widget.primaryFieldName}',
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final candidate = widget.candidates[index];
                  final selected = _selectedFieldId == candidate.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? PremiumTokens.brandGreen
                          : muted,
                    ),
                    title: Text(
                      candidate.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    subtitle: Text(
                      '${formatLinkedFieldAreaHa(candidate.areaHa)} ha',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    onTap: () => setState(() => _selectedFieldId = candidate.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ctaBg,
                      foregroundColor: ctaFg,
                    ),
                    onPressed: _isSaving || _selectedFieldId == null
                        ? null
                        : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
