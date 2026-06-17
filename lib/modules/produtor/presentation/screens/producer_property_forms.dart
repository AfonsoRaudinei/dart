part of 'producer_property_screen.dart';

Future<_FarmFormData?> _showFarmFormDialog(
  BuildContext context, {
  ProducerOwnFarm? farm,
}) {
  final nameController = TextEditingController(text: farm?.name ?? '');
  final cityController = TextEditingController(text: farm?.city ?? '');
  final stateController = TextEditingController(text: farm?.state ?? '');
  final areaController = TextEditingController(
    text: farm == null || farm.areaHa == 0
        ? ''
        : farm.areaHa.toStringAsFixed(1),
  );

  return showDialog<_FarmFormData>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(farm == null ? 'Cadastrar fazenda' : 'Editar fazenda'),
      content: _FarmFormFields(
        nameController: nameController,
        cityController: cityController,
        stateController: stateController,
        areaController: areaController,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(dialogContext).pop(
              _FarmFormData(
                name: name,
                city: cityController.text.trim(),
                state: stateController.text.trim(),
                areaHa: _parseArea(areaController.text),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    cityController.dispose();
    stateController.dispose();
    areaController.dispose();
  });
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
  final nameController = TextEditingController(text: field?.name ?? '');
  final areaController = TextEditingController(
    text: field == null || field.areaHa == 0
        ? ''
        : field.areaHa.toStringAsFixed(1),
  );

  return showDialog<_FieldFormData>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(field == null ? 'Cadastrar talhão' : 'Editar talhão'),
      content: _FieldFormFields(
        nameController: nameController,
        areaController: areaController,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(dialogContext).pop(
              _FieldFormData(
                name: name,
                areaHa: _parseArea(areaController.text),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    areaController.dispose();
  });
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
