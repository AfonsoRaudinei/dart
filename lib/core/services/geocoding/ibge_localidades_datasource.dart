import 'dart:convert';

import 'package:http/http.dart' as http;

/// Estado brasileiro (IBGE).
class IbgeEstado {
  const IbgeEstado({
    required this.id,
    required this.sigla,
    required this.nome,
  });

  final int id;
  final String sigla;
  final String nome;

  factory IbgeEstado.fromJson(Map<String, dynamic> json) {
    return IbgeEstado(
      id: json['id'] as int,
      sigla: json['sigla'] as String,
      nome: json['nome'] as String,
    );
  }
}

/// Município brasileiro (IBGE).
class IbgeMunicipio {
  const IbgeMunicipio({
    required this.id,
    required this.nome,
    required this.uf,
  });

  final int id;
  final String nome;
  final String uf;
}

/// Consulta localidades via API pública do IBGE.
class IbgeLocalidadesDatasource {
  IbgeLocalidadesDatasource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  List<IbgeEstado>? _estadosCache;
  final Map<int, List<IbgeMunicipio>> _municipiosCache = {};

  Future<List<IbgeEstado>> fetchEstados() async {
    if (_estadosCache != null) return _estadosCache!;

    final response = await _client.get(
      Uri.parse('$_baseUrl/estados?orderBy=nome'),
    );
    if (response.statusCode != 200) {
      throw const IbgeLocalidadesException('Não foi possível carregar os estados.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    _estadosCache = list
        .map((e) => IbgeEstado.fromJson(e as Map<String, dynamic>))
        .toList();
    return _estadosCache!;
  }

  Future<List<IbgeMunicipio>> fetchMunicipiosPorEstado(IbgeEstado estado) async {
    final cached = _municipiosCache[estado.id];
    if (cached != null) return cached;

    final response = await _client.get(
      Uri.parse('$_baseUrl/estados/${estado.id}/municipios?orderBy=nome'),
    );
    if (response.statusCode != 200) {
      throw IbgeLocalidadesException(
        'Não foi possível carregar municípios de ${estado.sigla}.',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    final municipios = list
        .map(
          (m) => IbgeMunicipio(
            id: (m as Map<String, dynamic>)['id'] as int,
            nome: m['nome'] as String,
            uf: estado.sigla,
          ),
        )
        .toList();
    _municipiosCache[estado.id] = municipios;
    return municipios;
  }

  /// Filtra municípios pelo termo de busca (case-insensitive).
  List<IbgeMunicipio> filterMunicipios(
    List<IbgeMunicipio> municipios,
    String query,
  ) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return municipios;
    return municipios
        .where((m) => m.nome.toLowerCase().contains(term))
        .toList();
  }
}

class IbgeLocalidadesException implements Exception {
  const IbgeLocalidadesException(this.message);

  final String message;

  @override
  String toString() => message;
}
