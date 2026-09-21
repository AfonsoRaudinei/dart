import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';

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
  bool _showSuccessBanner = false;

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
      setState(() => _showSuccessBanner = true);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
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
    return ClientSheetScaffold(
      title: 'Renomear talhão',
      banner: _showSuccessBanner
          ? const ClientSheetInlineBanner(
              message: 'Nome do talhão atualizado.',
            )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClientSheetFormField(
              controller: _nameController,
              label: 'Nome do talhão',
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do talhão';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ClientSheetButtonRow(
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm: () {
                HapticFeedback.mediumImpact();
                _submit();
              },
              confirmLabel: 'Salvar',
              isSaving: _isSaving,
              confirmEnabled: !_showSuccessBanner,
            ),
          ],
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

  return saved == true;
}
