part of 'producer_property_screen.dart';

Future<_FarmFormData?> _showFarmFormDialog(
  BuildContext context, {
  ProducerOwnFarm? farm,
}) {
  return showDialog<_FarmFormData>(
    context: context,
    builder: (dialogContext) => _FarmFormDialog(farm: farm),
  );
}

class _FarmFormDialog extends StatefulWidget {
  const _FarmFormDialog({this.farm});

  final ProducerOwnFarm? farm;

  @override
  State<_FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<_FarmFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    final farm = widget.farm;
    _nameController = TextEditingController(text: farm?.name ?? '');
    _cityController = TextEditingController(text: farm?.city ?? '');
    _stateController = TextEditingController(text: farm?.state ?? '');
    _areaController = TextEditingController(
      text: farm == null || farm.areaHa == 0
          ? ''
          : farm.areaHa.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.farm == null ? 'Cadastrar fazenda' : 'Editar fazenda'),
      content: _FarmFormFields(
        nameController: _nameController,
        cityController: _cityController,
        stateController: _stateController,
        areaController: _areaController,
      ),
      actions: [
        TextButton(
          onPressed: () {
            SoloforteKeyboardDismiss.dismiss();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            SoloforteKeyboardDismiss.dismiss();
            Navigator.of(context).pop(
              _FarmFormData(
                name: name,
                city: _cityController.text.trim(),
                state: _stateController.text.trim(),
                areaHa: _parseArea(_areaController.text),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

Future<bool?> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

Future<_FieldFormData?> _showFieldFormDialog(
  BuildContext context, {
  ProducerOwnField? field,
}) {
  return showDialog<_FieldFormData>(
    context: context,
    builder: (dialogContext) => _FieldFormDialog(field: field),
  );
}

class _FieldFormDialog extends StatefulWidget {
  const _FieldFormDialog({this.field});

  final ProducerOwnField? field;

  @override
  State<_FieldFormDialog> createState() => _FieldFormDialogState();
}

class _FieldFormDialogState extends State<_FieldFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    final field = widget.field;
    _nameController = TextEditingController(text: field?.name ?? '');
    _areaController = TextEditingController(
      text: field == null || field.areaHa == 0
          ? ''
          : field.areaHa.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.field == null ? 'Cadastrar talhão' : 'Editar talhão'),
      content: _FieldFormFields(
        nameController: _nameController,
        areaController: _areaController,
      ),
      actions: [
        TextButton(
          onPressed: () {
            SoloforteKeyboardDismiss.dismiss();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            SoloforteKeyboardDismiss.dismiss();
            Navigator.of(context).pop(
              _FieldFormData(
                name: name,
                areaHa: _parseArea(_areaController.text),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

double _parseArea(String value) {
  return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
}

class _FarmFormData {
  final String name;
  final String city;
  final String state;
  final double areaHa;

  const _FarmFormData({
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
  });
}

class _FieldFormData {
  final String name;
  final double areaHa;

  const _FieldFormData({required this.name, required this.areaHa});
}

class _FarmFormFields extends StatelessWidget {
  const _FarmFormFields({
    required this.nameController,
    required this.cityController,
    required this.stateController,
    required this.areaController,
  });

  final TextEditingController nameController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController areaController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nome da fazenda'),
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            controller: cityController,
            decoration: const InputDecoration(labelText: 'Município'),
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            controller: stateController,
            decoration: const InputDecoration(labelText: 'UF'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
          ),
          TextField(
            controller: areaController,
            decoration: const InputDecoration(labelText: 'Área total (ha)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}

class _FieldFormFields extends StatelessWidget {
  const _FieldFormFields({
    required this.nameController,
    required this.areaController,
  });

  final TextEditingController nameController;
  final TextEditingController areaController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome do talhão'),
          textCapitalization: TextCapitalization.words,
        ),
        TextField(
          controller: areaController,
          decoration: const InputDecoration(labelText: 'Área produtiva (ha)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
