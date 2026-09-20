import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_form_padding.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

enum TalhaoShortAction { editGeometry, editData, union }

String talhaoMapUri({
  required String modo,
  required String clientId,
  String? farmId,
  required String drawingId,
}) {
  return Uri(
    path: AppRoutes.map,
    queryParameters: {
      'modo': modo,
      'clienteId': clientId,
      if (farmId != null && farmId.isNotEmpty) 'fazendaId': farmId,
      'drawingId': drawingId,
    },
  ).toString();
}

Future<void> showTalhaoActionsSheet(
  BuildContext context, {
  required String clientId,
  String? farmId,
  required String fieldId,
  required String fieldName,
}) async {
  final action = await showSoloForteSheet<TalhaoShortAction>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (sheetContext) => TalhaoActionsSheet(
      fieldName: fieldName,
      onSelected: (selected) => Navigator.of(sheetContext).pop(selected),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case TalhaoShortAction.editGeometry:
      context.go(
        talhaoMapUri(
          modo: 'editar',
          clientId: clientId,
          farmId: farmId,
          drawingId: fieldId,
        ),
      );
    case TalhaoShortAction.union:
      context.go(
        talhaoMapUri(
          modo: 'uniao',
          clientId: clientId,
          farmId: farmId,
          drawingId: fieldId,
        ),
      );
    case TalhaoShortAction.editData:
      await showTalhaoDadosSheet(
        context,
        clientId: clientId,
        farmId: farmId,
        fieldId: fieldId,
        initialName: fieldName,
      );
  }
}

class TalhaoActionsSheet extends StatelessWidget {
  const TalhaoActionsSheet({
    super.key,
    required this.fieldName,
    required this.onSelected,
  });

  final String fieldName;
  final ValueChanged<TalhaoShortAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : null;
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final sheetBg = isIos ? Colors.transparent : Colors.white;
    final sheetRadius = isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : const Color(0xFFC5C5C7);

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
            Center(
              child: Container(
                width: isIos ? SoloForteSheetSkinIos.handleSize.width : 36,
                height: isIos ? SoloForteSheetSkinIos.handleSize.height : 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              fieldName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            _TalhaoActionTile(
              icon: Icons.edit_location,
              label: 'Editar geometria',
              description: 'Mover e ajustar vértices',
              muted: muted,
              titleColor: titleColor,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelected(TalhaoShortAction.editGeometry);
              },
            ),
            _TalhaoActionTile(
              icon: Icons.edit_note,
              label: 'Vincular / editar dados',
              description: 'Nome e fazenda',
              muted: muted,
              titleColor: titleColor,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelected(TalhaoShortAction.editData);
              },
            ),
            _TalhaoActionTile(
              icon: Icons.add_circle_outline,
              label: 'União',
              description: 'Combinar com outra área',
              muted: muted,
              titleColor: titleColor,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelected(TalhaoShortAction.union);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TalhaoActionTile extends StatelessWidget {
  const _TalhaoActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.muted,
    required this.titleColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color muted;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: PremiumTokens.brandGreen),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: muted, fontSize: 13),
      ),
      onTap: onTap,
    );
  }
}

Future<bool> showTalhaoDadosSheet(
  BuildContext context, {
  required String clientId,
  String? farmId,
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
    builder: (_) => TalhaoDadosSheet(
      clientId: clientId,
      farmId: farmId,
      fieldId: fieldId,
      initialName: initialName,
    ),
  );

  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados do talhão atualizados.')),
    );
  }

  return saved == true;
}

class TalhaoDadosSheet extends ConsumerStatefulWidget {
  const TalhaoDadosSheet({
    super.key,
    required this.clientId,
    this.farmId,
    required this.fieldId,
    required this.initialName,
  });

  final String clientId;
  final String? farmId;
  final String fieldId;
  final String initialName;

  @override
  ConsumerState<TalhaoDadosSheet> createState() => _TalhaoDadosSheetState();
}

class _TalhaoDadosSheetState extends ConsumerState<TalhaoDadosSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _repository = FarmRepository();
  List<Farm> _farms = const [];
  bool _isLoadingFarms = true;
  bool _isSaving = false;
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedFarmId = widget.farmId;
    _loadFarms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _repository.getFarmsByClientId(widget.clientId);
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _isLoadingFarms = false;
        if (_selectedFarmId != null &&
            farms.any((farm) => farm.id == _selectedFarmId)) {
          return;
        }
        if (farms.length == 1) {
          _selectedFarmId = farms.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _farms = const [];
        _isLoadingFarms = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      final writer = ref.read(iDrawingFieldWriterProvider);
      await writer.updateFieldName(
        fieldId: widget.fieldId,
        name: _nameController.text,
      );

      final nextFarmId = _selectedFarmId;
      if (nextFarmId != null &&
          nextFarmId.isNotEmpty &&
          nextFarmId != widget.farmId) {
        await writer.linkFieldToFarm(
          fieldId: widget.fieldId,
          clientId: widget.clientId,
          farmId: nextFarmId,
        );
      }

      ref.invalidate(clientDetailProvider(widget.clientId));
      ref.invalidate(clientDrawingFieldsProvider(widget.clientId));
      if (widget.farmId != null && widget.farmId!.isNotEmpty) {
        ref.invalidate(farmLinkedFieldsProvider(widget.farmId!));
      }
      if (nextFarmId != null &&
          nextFarmId.isNotEmpty &&
          nextFarmId != widget.farmId) {
        ref.invalidate(farmLinkedFieldsProvider(nextFarmId));
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Não foi possível salvar os dados'),
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
                'Dados do talhão',
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
              if (_isLoadingFarms) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ] else if (_farms.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _farms.any((farm) => farm.id == _selectedFarmId)
                      ? _selectedFarmId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda',
                    border: OutlineInputBorder(),
                  ),
                  items: _farms
                      .map(
                        (farm) => DropdownMenuItem(
                          value: farm.id,
                          child: Text(farm.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFarmId = value),
                ),
              ],
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
