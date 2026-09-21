import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_sheet_widgets.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_union_sheet.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';

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
  String? initialCultura,
  String? initialSafra,
  double? fieldAreaHa,
  List<LatLng> primaryVertices = const [],
  bool showUnionAction = false,
  List<TalhaoUnionCandidate> unionCandidates = const [],
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
      contextLine: fieldAreaHa != null
          ? buildTalhaoContextLine(
              areaHa: fieldAreaHa,
              cultura: initialCultura,
              safra: initialSafra,
            )
          : null,
      showUnionAction: showUnionAction && unionCandidates.isNotEmpty,
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
      await showTalhaoUnionSheet(
        context,
        clientId: clientId,
        farmId: farmId,
        primaryFieldId: fieldId,
        primaryFieldName: fieldName,
        primaryAreaHa: fieldAreaHa ?? 0,
        primaryVertices: primaryVertices,
        candidates: unionCandidates,
      );
    case TalhaoShortAction.editData:
      await showTalhaoDadosSheet(
        context,
        clientId: clientId,
        farmId: farmId,
        fieldId: fieldId,
        initialName: fieldName,
        initialCultura: initialCultura,
        initialSafra: initialSafra,
      );
  }
}

class TalhaoActionsSheet extends StatelessWidget {
  const TalhaoActionsSheet({
    super.key,
    required this.fieldName,
    required this.onSelected,
    this.contextLine,
    this.showUnionAction = false,
  });

  final String fieldName;
  final String? contextLine;
  final ValueChanged<TalhaoShortAction> onSelected;
  final bool showUnionAction;

  @override
  Widget build(BuildContext context) {
    final specs = <(TalhaoShortAction, IconData, String, String)>[
      (
        TalhaoShortAction.editGeometry,
        Icons.edit_location,
        'Editar geometria',
        'Mover e ajustar vértices',
      ),
      (
        TalhaoShortAction.editData,
        Icons.edit_note,
        'Vincular / editar dados',
        'Nome, fazenda, cultura e safra',
      ),
    ];
    if (showUnionAction) {
      specs.add((
        TalhaoShortAction.union,
        Icons.add_circle_outline,
        'União',
        'Combinar com outra área',
      ));
    }

    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i++) {
      final (action, icon, label, description) = specs[i];
      rows.add(
        TalhaoSheetActionRow(
          icon: icon,
          label: label,
          description: description,
          onTap: () => onSelected(action),
          showDivider: i < specs.length - 1,
        ),
      );
    }

    return TalhaoSheetScaffold(
      title: fieldName,
      contextLine: contextLine,
      child: TalhaoSheetActionCard(children: rows),
    );
  }
}

Future<bool> showTalhaoDadosSheet(
  BuildContext context, {
  required String clientId,
  String? farmId,
  required String fieldId,
  required String initialName,
  String? initialCultura,
  String? initialSafra,
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
      initialCultura: initialCultura,
      initialSafra: initialSafra,
    ),
  );

  return saved == true;
}

class TalhaoDadosSheet extends ConsumerStatefulWidget {
  const TalhaoDadosSheet({
    super.key,
    required this.clientId,
    this.farmId,
    required this.fieldId,
    required this.initialName,
    this.initialCultura,
    this.initialSafra,
  });

  final String clientId;
  final String? farmId;
  final String fieldId;
  final String initialName;
  final String? initialCultura;
  final String? initialSafra;

  @override
  ConsumerState<TalhaoDadosSheet> createState() => _TalhaoDadosSheetState();
}

class _TalhaoDadosSheetState extends ConsumerState<TalhaoDadosSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _culturaController;
  late final TextEditingController _safraController;
  final _repository = FarmRepository();
  List<Farm> _farms = const [];
  bool _isLoadingFarms = true;
  bool _isSaving = false;
  bool _showSuccessBanner = false;
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _culturaController = TextEditingController(text: widget.initialCultura ?? '');
    _safraController = TextEditingController(text: widget.initialSafra ?? '');
    _selectedFarmId = widget.farmId;
    _loadFarms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _culturaController.dispose();
    _safraController.dispose();
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

      await writer.updateFieldMetadata(
        fieldId: widget.fieldId,
        cultura: _culturaController.text,
        safra: _safraController.text,
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
      setState(() => _showSuccessBanner = true);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
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

  Widget _buildFarmPicker(TalhaoSheetVisuals visuals) {
    if (_isLoadingFarms) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TalhaoSheetSectionLabel(label: 'Fazenda'),
          TalhaoSheetFarmSkeleton(),
        ],
      );
    }

    if (_farms.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_farms.length == 1) {
      final farm = _farms.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TalhaoSheetSectionLabel(label: 'Fazenda'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: visuals.inputFill,
              borderRadius: BorderRadius.circular(visuals.cardRadius),
              border: Border.all(color: visuals.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    farm.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: visuals.titleColor,
                    ),
                  ),
                ),
                Icon(Icons.link, size: 18, color: visuals.muted),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TalhaoSheetSectionLabel(label: 'Fazenda'),
        ..._farms.map((farm) {
          final selected = farm.id == _selectedFarmId;
          return GestureDetector(
            onTap: () => setState(() => _selectedFarmId = farm.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? visuals.cardBg : visuals.inputFill,
                borderRadius: BorderRadius.circular(visuals.cardRadius),
                border: Border.all(
                  color: selected ? visuals.accent : visuals.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      farm.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: visuals.titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? visuals.accent : visuals.muted,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return ClientSheetScaffold(
      title: 'Dados do talhão',
      subtitle: 'Edite sem abrir o mapa',
      banner: _showSuccessBanner
          ? const ClientSheetInlineBanner(
              message: 'Dados do talhão atualizados.',
            )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TalhaoSheetFormField(
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TalhaoSheetFormField(
                    controller: _culturaController,
                    label: 'Cultura',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TalhaoSheetFormField(
                    controller: _safraController,
                    label: 'Safra',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFarmPicker(visuals),
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
