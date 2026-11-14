import 'parametro_comparativo.dart';

class AvaliacaoItem {
  final String id;
  final String titulo;
  final String nomeLadoA;
  final String nomeLadoB;
  final String? nomeLadoC;
  final String? fotoLadoAPath;
  final String? fotoLadoBPath;
  final String? fotoLadoCPath;
  final String? cultura;
  final List<ParametroComparativo> parametros;
  final String? observacoes;

  const AvaliacaoItem({
    required this.id,
    required this.titulo,
    this.nomeLadoA = 'Lado A',
    this.nomeLadoB = 'Lado B',
    this.nomeLadoC,
    this.fotoLadoAPath,
    this.fotoLadoBPath,
    this.fotoLadoCPath,
    this.cultura,
    this.parametros = const [],
    this.observacoes,
  });

  double get mediaGanhoPercent {
    if (parametros.isEmpty) return 0.0;
    final total = parametros.fold<double>(
      0,
      (sum, item) => sum + item.deltaPercent,
    );
    return total / parametros.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'nome_lado_a': nomeLadoA,
      'nome_lado_b': nomeLadoB,
      'nome_lado_c': nomeLadoC,
      'foto_lado_a_path': fotoLadoAPath,
      'foto_lado_b_path': fotoLadoBPath,
      'foto_lado_c_path': fotoLadoCPath,
      'cultura': cultura,
      'parametros': parametros.map((item) => item.toJson()).toList(),
      'observacoes': observacoes,
    };
  }

  factory AvaliacaoItem.fromJson(Map<String, dynamic> json) {
    final parametrosRaw = json['parametros'];
    return AvaliacaoItem(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      nomeLadoA: _rotulo(json, 'nome_lado_a', 'Lado A'),
      nomeLadoB: _rotulo(json, 'nome_lado_b', 'Lado B'),
      nomeLadoC: _rotuloOpcional(json, 'nome_lado_c'),
      fotoLadoAPath: json['foto_lado_a_path'] as String?,
      fotoLadoBPath: json['foto_lado_b_path'] as String?,
      fotoLadoCPath: json['foto_lado_c_path'] as String?,
      cultura: json['cultura'] as String?,
      parametros: parametrosRaw is List
          ? parametrosRaw
                .whereType<Map>()
                .map(
                  (item) => ParametroComparativo.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      observacoes: json['observacoes'] as String?,
    );
  }

  AvaliacaoItem copyWith({
    String? id,
    String? titulo,
    String? nomeLadoA,
    String? nomeLadoB,
    String? nomeLadoC,
    String? fotoLadoAPath,
    String? fotoLadoBPath,
    String? fotoLadoCPath,
    String? cultura,
    List<ParametroComparativo>? parametros,
    String? observacoes,
    bool clearNomeLadoC = false,
    bool clearFotoLadoA = false,
    bool clearFotoLadoB = false,
    bool clearFotoLadoC = false,
    bool clearCultura = false,
    bool clearObservacoes = false,
  }) {
    return AvaliacaoItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      nomeLadoA: nomeLadoA ?? this.nomeLadoA,
      nomeLadoB: nomeLadoB ?? this.nomeLadoB,
      nomeLadoC: clearNomeLadoC ? null : nomeLadoC ?? this.nomeLadoC,
      fotoLadoAPath: clearFotoLadoA
          ? null
          : fotoLadoAPath ?? this.fotoLadoAPath,
      fotoLadoBPath: clearFotoLadoB
          ? null
          : fotoLadoBPath ?? this.fotoLadoBPath,
      fotoLadoCPath: clearFotoLadoC
          ? null
          : fotoLadoCPath ?? this.fotoLadoCPath,
      cultura: clearCultura ? null : cultura ?? this.cultura,
      parametros: parametros ?? this.parametros,
      observacoes: clearObservacoes ? null : observacoes ?? this.observacoes,
    );
  }

  /// Chave ausente ou valor nulo mantém o fallback legado.
  /// String vazia é rótulo de propósito (slot sem nome) e não vira "Lado B".
  static String _rotulo(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    if (!json.containsKey(key)) return fallback;
    final raw = json[key];
    if (raw is! String) return fallback;
    return raw.trim();
  }

  static String? _rotuloOpcional(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) return null;
    final raw = json[key];
    if (raw is! String) return null;
    return raw.trim();
  }
}
