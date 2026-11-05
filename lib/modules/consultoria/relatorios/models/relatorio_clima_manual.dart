/// Clima manual opcional no relatório de visita (até 3 dias + pulverização).
///
/// Persistido em SQLite (`clima_manual_json`). Não sincroniza com Supabase.
class RelatorioClimaDiaManual {
  const RelatorioClimaDiaManual({this.data, this.resumo});

  /// Data ISO8601 (opcional).
  final String? data;

  /// Resumo textual do dia (opcional).
  final String? resumo;

  bool get hasContent => (resumo?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    if (data != null && data!.isNotEmpty) 'data': data,
    if (resumo != null && resumo!.isNotEmpty) 'resumo': resumo,
  };

  factory RelatorioClimaDiaManual.fromJson(Map<String, dynamic> json) {
    return RelatorioClimaDiaManual(
      data: json['data'] as String?,
      resumo: json['resumo'] as String?,
    );
  }

  RelatorioClimaDiaManual copyWith({String? data, String? resumo}) {
    return RelatorioClimaDiaManual(
      data: data ?? this.data,
      resumo: resumo ?? this.resumo,
    );
  }
}

class RelatorioClimaManual {
  const RelatorioClimaManual({this.dias = const [], this.pulverizacaoNota});

  static const int maxDias = 3;

  final List<RelatorioClimaDiaManual> dias;
  final String? pulverizacaoNota;

  static bool hasContent(RelatorioClimaManual? clima) {
    if (clima == null) return false;
    if (clima.pulverizacaoNota?.trim().isNotEmpty ?? false) return true;
    for (final dia in clima.dias) {
      if (dia.hasContent) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'dias': dias.map((e) => e.toJson()).toList(),
    if (pulverizacaoNota != null && pulverizacaoNota!.isNotEmpty)
      'pulverizacaoNota': pulverizacaoNota,
  };

  factory RelatorioClimaManual.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const RelatorioClimaManual();
    }
    final rawDias = json['dias'];
    final dias = <RelatorioClimaDiaManual>[];
    if (rawDias is List) {
      for (final item in rawDias.take(maxDias)) {
        if (item is Map<String, dynamic>) {
          dias.add(RelatorioClimaDiaManual.fromJson(item));
        } else if (item is Map) {
          dias.add(
            RelatorioClimaDiaManual.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return RelatorioClimaManual(
      dias: dias,
      pulverizacaoNota: json['pulverizacaoNota'] as String?,
    );
  }

  RelatorioClimaManual copyWith({
    List<RelatorioClimaDiaManual>? dias,
    String? pulverizacaoNota,
  }) {
    return RelatorioClimaManual(
      dias: dias ?? this.dias,
      pulverizacaoNota: pulverizacaoNota ?? this.pulverizacaoNota,
    );
  }
}
