import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'client_sheet_form_padding.dart';

/// Sheet para vincular um talhão do mapa a uma fazenda existente ou nova (1:1).
class LinkDrawingToFarmSheet extends ConsumerStatefulWidget {
  final Client client;
  final ClientDrawingFieldSummary field;
  final String? preselectedFarmId;

  const LinkDrawingToFarmSheet({
    super.key,
    required this.client,
    required this.field,
    this.preselectedFarmId,
  });

  @override
  ConsumerState<LinkDrawingToFarmSheet> createState() =>
      _LinkDrawingToFarmSheetState();
}

class _LinkDrawingToFarmSheetState
    extends ConsumerState<LinkDrawingToFarmSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _repository = FarmRepository();
  List<Farm> _farms = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showCreateForm = false;
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.field.name.trim().isEmpty
        ? 'Fazenda ${widget.client.name}'
        : widget.field.name;
    _cityController.text = widget.client.city;
    _stateController.text = widget.client.state;
    _loadFarms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() => _isLoading = true);
    try {
      final farms = await _repository.getFarmsByClientId(widget.client.id);
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _isLoading = false;
        _showCreateForm = farms.isEmpty;
        if (widget.preselectedFarmId != null &&
            farms.any((f) => f.id == widget.preselectedFarmId)) {
          _selectedFarmId = widget.preselectedFarmId;
          _showCreateForm = false;
        } else if (farms.length == 1) {
          _selectedFarmId = farms.first.id;
        } else if (widget.field.farmId != null) {
          _selectedFarmId = widget.field.farmId;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _farms = const [];
        _isLoading = false;
        _showCreateForm = true;
      });
    }
  }

  Farm? get _selectedFarm {
    for (final farm in _farms) {
      if (farm.id == _selectedFarmId) return farm;
    }
    return null;
  }

  Future<void> _linkToFarm(Farm farm) async {
    await ref.read(iDrawingFieldWriterProvider).linkFieldToFarm(
          fieldId: widget.field.id,
          clientId: widget.client.id,
          farmId: farm.id,
        );
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_showCreateForm) {
      if (_formKey.currentState?.validate() != true) return;
    } else if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma fazenda para vincular.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      late final Farm farm;
      if (_showCreateForm) {
        farm = Farm(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim().toUpperCase(),
          totalAreaHa: widget.field.areaHa,
          fields: const [],
        );
        await _repository.saveFarm(farm, widget.client.id);
      } else {
        farm = _selectedFarm!;
      }

      await _linkToFarm(farm);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: false).pop(farm);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível vincular o talhão à fazenda.'),
        ),
      );
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
    final accent =
        isIos ? SoloForteSheetSkinIos.iconStroke : PremiumTokens.brandGreen;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : PremiumTokens.brandGreen;
    final ctaFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final ctaRadius =
        isIos ? SoloForteSheetSkinIos.ctaRadius : 8.0;
    final sheetBg =
        isIos ? SoloForteSheetSkinIos.background : Colors.white;
    final sheetRadius =
        isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isIos)
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
                  'Vincular à fazenda',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Associe "${widget.field.name}" a uma fazenda. Uma fazenda pode ter apenas este talhão.',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_farms.isNotEmpty && !_showCreateForm)
                    _buildFarmList(isIos),
                  if (_farms.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showCreateForm = !_showCreateForm;
                          if (_showCreateForm) {
                            _selectedFarmId = null;
                          }
                        });
                      },
                      icon: Icon(
                        _showCreateForm ? Icons.list_alt : Icons.add,
                        color: accent,
                      ),
                      label: Text(
                        _showCreateForm
                            ? 'Usar fazenda existente'
                            : 'Criar fazenda com este talhão',
                        style: TextStyle(color: accent),
                      ),
                    ),
                  if (_showCreateForm) ...[
                    const SizedBox(height: 8),
                    _buildCreateForm(isIos),
                  ],
                ],
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
                    onPressed: (_isLoading || _isSaving) ? null : _submit,
                    child: Text(
                      _isSaving
                          ? 'Vinculando...'
                          : (_showCreateForm
                              ? 'Criar fazenda e vincular'
                              : 'Vincular talhão'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmList(bool isIos) {
    final accent =
        isIos ? SoloForteSheetSkinIos.iconStroke : PremiumTokens.brandGreen;
    final selectedBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFFEFFAF2);
    final unselectedBg =
        isIos ? SoloForteSheetSkinIos.background : Colors.white;
    final unselectedBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : const Color(0xFFE2E2E8);
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : null;
    final unchecked =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.black38;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fazendas cadastradas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        ..._farms.map((farm) {
          final selected = farm.id == _selectedFarmId;
          return GestureDetector(
            onTap: () => setState(() => _selectedFarmId = farm.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: selected ? accent : unselectedBorder,
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
                        color: titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? accent : unchecked,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCreateForm(bool isIos) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Criar fazenda com este talhão',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isIos ? SoloForteSheetSkinIos.titleColor : null,
            ),
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
        ],
      ),
    );
  }
}

Future<Farm?> showLinkDrawingToFarmSheet(
  BuildContext context, {
  required Client client,
  required ClientDrawingFieldSummary field,
  String? preselectedFarmId,
}) {
  return showSoloForteSheet<Farm>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => LinkDrawingToFarmSheet(
      client: client,
      field: field,
      preselectedFarmId: preselectedFarmId,
    ),
  );
}
