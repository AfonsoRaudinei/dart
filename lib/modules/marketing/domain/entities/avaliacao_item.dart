import 'parametro_comparativo.dart';

class AvaliacaoItem {
  final String id;
  final String titulo;
  final String nomeLadoA;
  final String nomeLadoB;
  final String? fotoLadoAPath;
  final String? fotoLadoBPath;
  final String? cultura;
  final List<ParametroComparativo> parametros;
  final String? observacoes;

  const AvaliacaoItem({
    required this.id,
    required this.titulo,
    this.nomeLadoA = 'Lado A',
    this.nomeLadoB = 'Lado B',
    this.fotoLadoAPath,
    this.fotoLadoBPath,
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
      'foto_lado_a_path': fotoLadoAPath,
      'foto_lado_b_path': fotoLadoBPath,
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
      nomeLadoA: _nonEmpty(json['nome_lado_a'] as String?, 'Lado A'),
      nomeLadoB: _nonEmpty(json['nome_lado_b'] as String?, 'Lado B'),
      fotoLadoAPath: json['foto_lado_a_path'] as String?,
      fotoLadoBPath: json['foto_lado_b_path'] as String?,
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
    String? fotoLadoAPath,
    String? fotoLadoBPath,
    String? cultura,
    List<ParametroComparativo>? parametros,
    String? observacoes,
    bool clearFotoLadoA = false,
    bool clearFotoLadoB = false,
    bool clearCultura = false,
    bool clearObservacoes = false,
  }) {
    return AvaliacaoItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      nomeLadoA: nomeLadoA ?? this.nomeLadoA,
      nomeLadoB: nomeLadoB ?? this.nomeLadoB,
      fotoLadoAPath: clearFotoLadoA
          ? null
          : fotoLadoAPath ?? this.fotoLadoAPath,
      fotoLadoBPath: clearFotoLadoB
          ? null
          : fotoLadoBPath ?? this.fotoLadoBPath,
      cultura: clearCultura ? null : cultura ?? this.cultura,
      parametros: parametros ?? this.parametros,
      observacoes: clearObservacoes ? null : observacoes ?? this.observacoes,
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}
