import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_map_entry_sheet.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5C5C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  'Nova fazenda',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cadastre a fazenda por nome. Você pode vincular talhões depois.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
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
                      backgroundColor: PremiumTokens.brandGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
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
    );
  }
}

Future<void> showCreateFarmSheet(
  BuildContext context, {
  required Client client,
  required VoidCallback onFarmCreated,
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
      onCreated: (_) {
        Navigator.of(context, rootNavigator: false).pop();
        onFarmCreated();
      },
    ),
  );
}
