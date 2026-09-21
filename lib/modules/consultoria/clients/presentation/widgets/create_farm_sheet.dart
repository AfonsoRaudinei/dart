import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/brazilian_state_dropdown.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_map_entry_sheet.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:uuid/uuid.dart';

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
  final _areaController = TextEditingController();
  String? _selectedUf;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.client.city;
    _selectedUf = BrazilianStateDropdown.resolveInitialUf(widget.client.state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
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
          state: _selectedUf!.toUpperCase(),
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
    return ClientSheetScaffold(
      title: 'Nova fazenda',
      subtitle: 'Cadastre a fazenda por nome. Você pode vincular talhões depois.',
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClientSheetFormField(
                controller: _nameController,
                label: 'Nome da fazenda',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da fazenda';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClientSheetFormField(
                controller: _cityController,
                label: 'Município',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o município';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClientSheetSectionLabel(label: 'UF'),
              BrazilianStateDropdown(
                value: _selectedUf,
                onChanged: (value) => setState(() => _selectedUf = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione a UF';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClientSheetFormField(
                controller: _areaController,
                label: 'Área total (ha) — opcional',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
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
              const SizedBox(height: 20),
              ClientSheetPrimaryButton(
                label: _isSaving ? 'Salvando...' : 'Salvar fazenda',
                isSaving: _isSaving,
                onPressed: _submit,
              ),
            ],
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
