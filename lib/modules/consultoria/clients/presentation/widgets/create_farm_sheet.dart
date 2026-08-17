import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_map_entry_sheet.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:uuid/uuid.dart';
import 'client_sheet_form_padding.dart';

/// Sheet de cadastro de fazenda por nome (sem forçar abertura do mapa).
class CreateFarmSheet extends StatefulWidget {
  final Client client;
  final Future<Farm> Function(String clientId, FarmDraftData draft) createFarm;
  final ValueChanged<Farm> onCreated;

  const CreateFarmSheet({
    super.key,
    required this.client,
    required this.createFarm,
    required this.onCreated,
  });

  @override
  State<CreateFarmSheet> createState() => _CreateFarmSheetState();
}

class _CreateFarmSheetState extends State<CreateFarmSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.client.city;
    _stateController.text = widget.client.state;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  double _parseArea(String value) {
    final trimmed = value.replaceAll(',', '.').trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed) ?? 0;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      final farm = await widget.createFarm(
        widget.client.id,
        FarmDraftData(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim().toUpperCase(),
          areaHa: _parseArea(_areaController.text),
        ),
      );
      if (!mounted) return;
      widget.onCreated(farm);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : null;
    final subtitleColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.black54;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : PremiumTokens.brandGreen;
    final ctaFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final ctaRadius =
        isIos ? SoloForteSheetSkinIos.ctaRadius : 8.0;
    // Modal já pinta prata iOS — evitar segundo painel opaco (“dois sheets”).
    final sheetBg =
        isIos ? Colors.transparent : Colors.white;
    final sheetRadius =
        isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : const Color(0xFFC5C5C7);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      padding: clientSheetFormPadding(context),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: ctaBg),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: isIos
                          ? SoloForteSheetSkinIos.handleSize.width
                          : 36,
                      height: isIos
                          ? SoloForteSheetSkinIos.handleSize.height
                          : 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Nova fazenda',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre a fazenda por nome. Você pode vincular talhões depois.',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da fazenda',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da fazenda';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Município'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o município';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    decoration: const InputDecoration(labelText: 'UF'),
                    validator: (value) {
                      if (value == null || value.trim().length != 2) {
                        return 'Informe a UF com 2 letras';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Área total (ha) — opcional',
                    ),
                    validator: (value) {
                      final trimmed = (value ?? '').trim();
                      if (trimmed.isEmpty) return null;
                      final area = _parseArea(trimmed);
                      if (area < 0) {
                        return 'Informe uma área válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ctaBg,
                        foregroundColor: ctaFg,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ctaRadius),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: Text(_isSaving ? 'Salvando...' : 'Salvar fazenda'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showCreateFarmSheet(
  BuildContext context, {
  required Client client,
  required ValueChanged<Farm> onFarmCreated,
}) {
  final repository = FarmRepository();

  return showSoloForteSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => CreateFarmSheet(
      client: client,
      createFarm: (clientId, draft) async {
        final farm = Farm(
          id: const Uuid().v4(),
          name: draft.name,
          city: draft.city,
          state: draft.state,
          totalAreaHa: draft.areaHa,
          fields: const [],
        );
        await repository.saveFarm(farm, clientId);
        return farm;
      },
      onCreated: (farm) {
        Navigator.of(context, rootNavigator: false).pop();
        onFarmCreated(farm);
      },
    ),
  );
}
