import 'package:flutter/material.dart';

/// Dropdown de UF brasileira (sigla de 2 letras) com lista estática das 27 UFs.
class BrazilianStateDropdown extends StatelessWidget {
  const BrazilianStateDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  static const List<({String sigla, String nome})> _states = [
    (sigla: 'AC', nome: 'Acre'),
    (sigla: 'AL', nome: 'Alagoas'),
    (sigla: 'AP', nome: 'Amapá'),
    (sigla: 'AM', nome: 'Amazonas'),
    (sigla: 'BA', nome: 'Bahia'),
    (sigla: 'CE', nome: 'Ceará'),
    (sigla: 'DF', nome: 'Distrito Federal'),
    (sigla: 'ES', nome: 'Espírito Santo'),
    (sigla: 'GO', nome: 'Goiás'),
    (sigla: 'MA', nome: 'Maranhão'),
    (sigla: 'MT', nome: 'Mato Grosso'),
    (sigla: 'MS', nome: 'Mato Grosso do Sul'),
    (sigla: 'MG', nome: 'Minas Gerais'),
    (sigla: 'PA', nome: 'Pará'),
    (sigla: 'PB', nome: 'Paraíba'),
    (sigla: 'PR', nome: 'Paraná'),
    (sigla: 'PE', nome: 'Pernambuco'),
    (sigla: 'PI', nome: 'Piauí'),
    (sigla: 'RJ', nome: 'Rio de Janeiro'),
    (sigla: 'RN', nome: 'Rio Grande do Norte'),
    (sigla: 'RS', nome: 'Rio Grande do Sul'),
    (sigla: 'RO', nome: 'Rondônia'),
    (sigla: 'RR', nome: 'Roraima'),
    (sigla: 'SC', nome: 'Santa Catarina'),
    (sigla: 'SP', nome: 'São Paulo'),
    (sigla: 'SE', nome: 'Sergipe'),
    (sigla: 'TO', nome: 'Tocantins'),
  ];

  static final Map<String, String> _siglaByNome = {
    for (final state in _states) state.nome.toLowerCase(): state.sigla,
  };

  static final Set<String> _validSiglas = {
    for (final state in _states) state.sigla,
  };

  /// Resolve valor inicial: sigla válida (case-insensitive) ou nome completo do estado.
  static String? resolveInitialUf(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final upper = trimmed.toUpperCase();
    if (upper.length == 2 && _validSiglas.contains(upper)) {
      return upper;
    }

    return _siglaByNome[trimmed.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'UF'),
      items: _states
          .map(
            (state) => DropdownMenuItem<String>(
              value: state.sigla,
              child: Text('${state.nome} (${state.sigla})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
