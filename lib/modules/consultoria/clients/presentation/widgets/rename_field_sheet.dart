import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import 'client_sheet_form_padding.dart';

class RenameFieldSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String farmId;
  final String fieldId;
  final String initialName;

  const RenameFieldSheet({
    super.key,
    required this.clientId,
    required this.farmId,
    required this.fieldId,
    required this.initialName,
  });

  @override
  ConsumerState<RenameFieldSheet> createState() => _RenameFieldSheetState();
}

class _RenameFieldSheetState extends ConsumerState<RenameFieldSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(iDrawingFieldWriterProvider).updateFieldName(
            fieldId: widget.fieldId,
            name: _nameController.text,
          );

      ref.invalidate(farmLinkedFieldsProvider(widget.farmId));
      ref.invalidate(clientDetailProvider(widget.clientId));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Não foi possível renomear o talhão'),
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Renomear talhão',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do talhão',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do talhão';
                  }
                  return null;
                },
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
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> showRenameFieldSheet(
  BuildContext context, {
  required String clientId,
  required String farmId,
  required String fieldId,
  required String initialName,
}) async {
  final saved = await showSoloForteSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => RenameFieldSheet(
      clientId: clientId,
      farmId: farmId,
      fieldId: fieldId,
      initialName: initialName,
    ),
  );

  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome do talhão atualizado.')),
    );
  }

  return saved == true;
}
