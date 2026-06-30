import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:uuid/uuid.dart';

enum FarmMapEntryMode {
  draw('desenho'),
  import('importar');

  const FarmMapEntryMode(this.queryValue);

  final String queryValue;

  String get title => switch (this) {
    FarmMapEntryMode.draw => 'Preparar desenho',
    FarmMapEntryMode.import => 'Preparar importação',
  };

  String get continueLabel => switch (this) {
    FarmMapEntryMode.draw => 'Continuar para desenhar',
    FarmMapEntryMode.import => 'Continuar para importar',
  };
}

Uri buildFarmMapUri({
  required Client client,
  required Farm farm,
  required FarmMapEntryMode mode,
}) {
  return Uri(
    path: AppRoutes.map,
    queryParameters: {
      'modo': mode.queryValue,
      'clienteId': client.id,
      'clienteNome': client.name,
      'fazendaId': farm.id,
      'fazendaNome': farm.name,
    },
  );
}

class FarmDraftData {
  final String name;
  final String city;
  final String state;
  final double areaHa;

  const FarmDraftData({
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
  });
}

class FarmMapEntrySheet extends StatefulWidget {
  final Client client;
  final FarmMapEntryMode mode;
  final Future<List<Farm>> Function(String clientId) loadFarms;
  final Future<Farm> Function(String clientId, FarmDraftData draft) createFarm;
  final ValueChanged<Farm> onConfirmed;

  const FarmMapEntrySheet({
    super.key,
    required this.client,
    required this.mode,
    required this.loadFarms,
    required this.createFarm,
    required this.onConfirmed,
  });

  @override
  State<FarmMapEntrySheet> createState() => _FarmMapEntrySheetState();
}

class _FarmMapEntrySheetState extends State<FarmMapEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _areaController = TextEditingController();

  List<Farm> _farms = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showCreateForm = false;
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.client.city;
    _stateController.text = widget.client.state;
    _loadFarms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() => _isLoading = true);
    try {
      final farms = await widget.loadFarms(widget.client.id);
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _isLoading = false;
        _showCreateForm = farms.isEmpty;
        if (farms.length == 1) {
          _selectedFarmId = farms.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _farms = const [];
        _isLoading = false;
        _showCreateForm = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar as fazendas do cliente.'),
        ),
      );
    }
  }

  double _parseArea(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  Farm? get _selectedFarm {
    for (final farm in _farms) {
      if (farm.id == _selectedFarmId) return farm;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_showCreateForm) {
      if (_formKey.currentState?.validate() != true) return;
      setState(() => _isSaving = true);
      try {
        final createdFarm = await widget.createFarm(
          widget.client.id,
          FarmDraftData(
            name: _nameController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim().toUpperCase(),
            areaHa: _parseArea(_areaController.text),
          ),
        );
        if (!mounted) return;
        widget.onConfirmed(createdFarm);
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
      return;
    }

    final selectedFarm = _selectedFarm;
    if (selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma fazenda para continuar.')),
      );
      return;
    }
    widget.onConfirmed(selectedFarm);
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
              Text(
                widget.mode.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha uma fazenda existente ou cadastre uma nova antes de abrir o mapa para ${widget.mode == FarmMapEntryMode.draw ? 'desenhar' : 'importar o arquivo'}.',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _buildClientSummary(),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_farms.isNotEmpty) _buildFarmList(),
                const SizedBox(height: 12),
                _buildToggleAction(),
                if (_showCreateForm) ...[
                  const SizedBox(height: 16),
                  _buildCreateForm(),
                ],
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: (_isLoading || _isSaving) ? null : _submit,
                  child: Text(
                    _isSaving ? 'Salvando...' : widget.mode.continueLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cliente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.client.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fazendas cadastradas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._farms.map((farm) {
          final selected = farm.id == _selectedFarmId;
          final location = [
            if (farm.city.trim().isNotEmpty) farm.city.trim(),
            if (farm.state.trim().isNotEmpty) farm.state.trim().toUpperCase(),
          ].join(' - ');
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFarmId = farm.id;
                _showCreateForm = false;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFFAF2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? PremiumTokens.brandGreen
                      : const Color(0xFFE2E2E8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${farm.totalAreaHa.toStringAsFixed(2)} ha',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? PremiumTokens.brandGreen
                            : Colors.black38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildToggleAction() {
    final hasFarms = _farms.isNotEmpty;
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _showCreateForm = !_showCreateForm;
          if (_showCreateForm) {
            _selectedFarmId = null;
          }
        });
      },
      icon: Icon(
        _showCreateForm && hasFarms ? Icons.list_alt : Icons.add,
        color: PremiumTokens.brandGreen,
      ),
      label: Text(
        _showCreateForm && hasFarms
            ? 'Usar fazenda existente'
            : 'Cadastrar nova fazenda',
        style: const TextStyle(color: PremiumTokens.brandGreen),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nova fazenda',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome da fazenda'),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Área total (ha)'),
            validator: (value) {
              final area = _parseArea(value ?? '');
              if (area <= 0) {
                return 'Informe uma área maior que zero';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showFarmMapEntrySheet(
  BuildContext context, {
  required Client client,
  required FarmMapEntryMode mode,
}) {
  final repository = FarmRepository();

  return showSoloForteSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => FarmMapEntrySheet(
      client: client,
      mode: mode,
      loadFarms: repository.getFarmsByClientId,
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
      onConfirmed: (farm) {
        Navigator.of(context, rootNavigator: false).pop();
        context.go(
          buildFarmMapUri(client: client, farm: farm, mode: mode).toString(),
        );
      },
    ),
  );
}
