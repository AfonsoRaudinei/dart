/// DTO: VisitSessionSnapshot — ADR-009
///
/// CONTRATO FIXO:
///   Este DTO pertence ao bounded context [consultoria/relatorios].
///   NÃO importa nenhuma classe de lib/modules/operacao/.
///   Define apenas o que [RelatorioTecnico] precisa saber sobre uma visita.
///   É imutável: uma vez criado, não reflete mudanças na VisitSession original.
library;

// ============================================================
// TIPOS DE SUPORTE (snapshots imutáveis)
// ============================================================

/// Snapshot imutável de uma ocorrência registrada durante a visita.
///
/// Contém apenas os dados necessários para compor o relatório.
/// Não faz referência a nenhuma entidade de [operacao].
class OcorrenciaSnapshot {
  /// Identificador da ocorrência original (UUID).
  final String id;

  /// Tipo/categoria da ocorrência (ex.: "praga", "doença").
  final String tipo;

  /// Descrição textual registrada pelo agrônomo.
  final String descricao;

  /// Latitude do ponto de ocorrência (opcional).
  final double? lat;

  /// Longitude do ponto de ocorrência (opcional).
  final double? lng;

  /// Path local da foto vinculada (opcional).
  final String? fotoPath;

  /// Data/hora em que a ocorrência foi registrada (UTC).
  final DateTime registradaEm;

  const OcorrenciaSnapshot({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.lat,
    this.lng,
    this.fotoPath,
    required this.registradaEm,
  });

  OcorrenciaSnapshot copyWith({
    String? id,
    String? tipo,
    String? descricao,
    double? lat,
    double? lng,
    String? fotoPath,
    DateTime? registradaEm,
  }) {
    return OcorrenciaSnapshot(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      fotoPath: fotoPath ?? this.fotoPath,
      registradaEm: registradaEm ?? this.registradaEm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'descricao': descricao,
    'lat': lat,
    'lng': lng,
    'fotoPath': fotoPath,
    'registradaEm': registradaEm.toUtc().toIso8601String(),
  };

  factory OcorrenciaSnapshot.fromJson(Map<String, dynamic> json) =>
      OcorrenciaSnapshot(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        fotoPath: json['fotoPath'] as String?,
        registradaEm: DateTime.parse(json['registradaEm'] as String).toUtc(),
      );
}

// ============================================================

/// Snapshot de um talhão visitado durante a sessão.
class TalhaoVisitado {
  /// Identificador do talhão (UUID).
  final String talhaoId;

  /// Nome do talhão.
  final String nomeTalhao;

  /// Área em hectares (opcional).
  final double? areaHectares;

  /// Cultura plantada no talhão (opcional).
  final String? cultura;

  /// Safra de referência (opcional).
  final String? safra;

  const TalhaoVisitado({
    required this.talhaoId,
    required this.nomeTalhao,
    this.areaHectares,
    this.cultura,
    this.safra,
  });

  TalhaoVisitado copyWith({
    String? talhaoId,
    String? nomeTalhao,
    double? areaHectares,
    String? cultura,
    String? safra,
  }) {
    return TalhaoVisitado(
      talhaoId: talhaoId ?? this.talhaoId,
      nomeTalhao: nomeTalhao ?? this.nomeTalhao,
      areaHectares: areaHectares ?? this.areaHectares,
      cultura: cultura ?? this.cultura,
      safra: safra ?? this.safra,
    );
  }

  Map<String, dynamic> toJson() => {
    'talhaoId': talhaoId,
    'nomeTalhao': nomeTalhao,
    'areaHectares': areaHectares,
    'cultura': cultura,
    'safra': safra,
  };

  factory TalhaoVisitado.fromJson(Map<String, dynamic> json) => TalhaoVisitado(
    talhaoId: json['talhaoId'] as String,
    nomeTalhao: json['nomeTalhao'] as String,
    areaHectares: (json['areaHectares'] as num?)?.toDouble(),
    cultura: json['cultura'] as String?,
    safra: json['safra'] as String?,
  );
}

// ============================================================

/// Snapshot de um dado de monitoramento coletado durante a visita.
class MonitoramentoSnapshot {
  /// Identificador do registro de monitoramento (UUID).
  final String id;

  /// Tipo de monitoramento (ex.: "MIP", "NDVI", "fenologia").
  final String tipo;

  /// Dados estruturados coletados (chave/valor).
  final Map<String, dynamic> dados;

  /// Data/hora da coleta (UTC).
  final DateTime coletadoEm;

  const MonitoramentoSnapshot({
    required this.id,
    required this.tipo,
    required this.dados,
    required this.coletadoEm,
  });

  MonitoramentoSnapshot copyWith({
    String? id,
    String? tipo,
    Map<String, dynamic>? dados,
    DateTime? coletadoEm,
  }) {
    return MonitoramentoSnapshot(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      dados: dados ?? this.dados,
      coletadoEm: coletadoEm ?? this.coletadoEm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'dados': dados,
    'coletadoEm': coletadoEm.toUtc().toIso8601String(),
  };

  factory MonitoramentoSnapshot.fromJson(Map<String, dynamic> json) =>
      MonitoramentoSnapshot(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        dados: Map<String, dynamic>.from(json['dados'] as Map),
        coletadoEm: DateTime.parse(json['coletadoEm'] as String).toUtc(),
      );
}

// ============================================================
// DTO PRINCIPAL
// ============================================================

/// DTO imutável com os dados da sessão de visita necessários para gerar
/// um [RelatorioTecnico].
///
/// REGRA ADR-009:
///   Este DTO não importa nem referencia nenhuma classe de
///   lib/modules/operacao/. É o contrato de fronteira entre os módulos.
///   Quem constrói este DTO (ex.: map/ ou a camada de apresentação)
///   é responsável por mapear os dados de VisitSession para este formato.
class VisitSessionSnapshot {
  /// ID da VisitSession original (referência — sem importar a entidade).
  final String sessionId;

  /// ID do cliente associado à visita.
  final String clientId;

  /// Nome da fazenda visitada.
  final String farmName;

  /// ID do agrônomo responsável pela visita.
  final String agronomistId;

  /// Data/hora real de início da visita (UTC).
  final DateTime startedAt;

  /// Data/hora real de encerramento da visita (UTC).
  final DateTime finishedAt;

  /// Ocorrências registradas durante a visita.
  final List<OcorrenciaSnapshot> ocorrencias;

  /// Talhões visitados na sessão.
  final List<TalhaoVisitado> talhoes;

  /// Paths locais das fotos registradas na visita.
  final List<String> fotos;

  /// Dados de monitoramento coletados na visita.
  final List<MonitoramentoSnapshot> monitoramentos;

  const VisitSessionSnapshot({
    required this.sessionId,
    required this.clientId,
    required this.farmName,
    required this.agronomistId,
    required this.startedAt,
    required this.finishedAt,
    this.ocorrencias = const [],
    this.talhoes = const [],
    this.fotos = const [],
    this.monitoramentos = const [],
  });

  VisitSessionSnapshot copyWith({
    String? sessionId,
    String? clientId,
    String? farmName,
    String? agronomistId,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<OcorrenciaSnapshot>? ocorrencias,
    List<TalhaoVisitado>? talhoes,
    List<String>? fotos,
    List<MonitoramentoSnapshot>? monitoramentos,
  }) {
    return VisitSessionSnapshot(
      sessionId: sessionId ?? this.sessionId,
      clientId: clientId ?? this.clientId,
      farmName: farmName ?? this.farmName,
      agronomistId: agronomistId ?? this.agronomistId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      ocorrencias: ocorrencias ?? this.ocorrencias,
      talhoes: talhoes ?? this.talhoes,
      fotos: fotos ?? this.fotos,
      monitoramentos: monitoramentos ?? this.monitoramentos,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'clientId': clientId,
    'farmName': farmName,
    'agronomistId': agronomistId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'ocorrencias': ocorrencias.map((e) => e.toJson()).toList(),
    'talhoes': talhoes.map((e) => e.toJson()).toList(),
    'fotos': fotos,
    'monitoramentos': monitoramentos.map((e) => e.toJson()).toList(),
  };

  factory VisitSessionSnapshot.fromJson(Map<String, dynamic> json) =>
      VisitSessionSnapshot(
        sessionId: json['sessionId'] as String,
        clientId: json['clientId'] as String,
        farmName: json['farmName'] as String,
        agronomistId: json['agronomistId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        finishedAt: DateTime.parse(json['finishedAt'] as String).toUtc(),
        ocorrencias:
            (json['ocorrencias'] as List<dynamic>?)
                ?.map(
                  (e) => OcorrenciaSnapshot.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        talhoes:
            (json['talhoes'] as List<dynamic>?)
                ?.map((e) => TalhaoVisitado.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        fotos: (json['fotos'] as List<dynamic>?)?.cast<String>() ?? [],
        monitoramentos:
            (json['monitoramentos'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      MonitoramentoSnapshot.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
