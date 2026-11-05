import 'package:latlong2/latlong.dart';

/// Status do ciclo de vida de uma sessão de medição GPS Walk.
enum GpsWalkStatus {
  /// Modo selecionado mas medição ainda não iniciada.
  idle,

  /// Coleta de pontos GPS ativa.
  measuring,

  /// Coleta suspensa temporariamente; pontos preservados.
  paused,

  /// GPS parado com o traço aberto. Nada foi salvo.
  stoppedOpen,

  /// Sessão concluída; geometria enviada ao DrawingController.
  finished,
}

/// Estado imutável de uma sessão de medição GPS Walk.
///
/// Representa o ciclo completo de coleta de pontos GPS em campo:
/// idle → measuring → paused → measuring → stoppedOpen | finished
///
/// ### Responsabilidades
/// - Armazenar pontos coletados (espelho de DrawingController.gpsVertices)
/// - Armazenar a distância do caminho aberto (sem volta ao início)
/// - Rastrear modo de coleta (automático vs manual)
///
/// ### Imutabilidade
/// Toda mutação cria uma nova instância via [copyWith].
/// Fonte da verdade durante sessão: estado em memória.
/// Ao finalizar, geometria é transferida ao DrawingController.
///
/// ### Validação
/// Fechar o desenho exige 3 pontos. Parar sem fechar exige 2.
class GpsWalkSession {
  /// Pontos GPS aceitos durante a sessão.
  final List<LatLng> points;

  /// Status atual da sessão.
  final GpsWalkStatus status;

  /// Distância do caminho aberto, em metros (sem volta ao início).
  ///
  /// [perimeterMeters] recebe o mesmo valor enquanto o traço está aberto,
  /// para leituras antigas não somarem a aresta de fechamento.
  final double distanceMeters;

  /// Espelho de [distanceMeters] enquanto o traço está aberto.
  final double perimeterMeters;

  /// Área calculada em tempo real (metros quadrados).
  ///
  /// Não é exibida enquanto o traço está aberto.
  final double areaSquareMeters;

  /// Modo de coleta: `true` = GPS automático, `false` = toque manual.
  final bool isAutoMode;

  /// Momento em que a medição foi iniciada.
  final DateTime? startedAt;

  /// Momento em que a sessão foi concluída.
  final DateTime? finishedAt;

  const GpsWalkSession({
    required this.points,
    required this.status,
    required this.perimeterMeters,
    required this.areaSquareMeters,
    this.distanceMeters = 0,
    this.isAutoMode = true,
    this.startedAt,
    this.finishedAt,
  });

  /// Estado inicial: nenhum ponto, modo idle, coleta automática.
  factory GpsWalkSession.initial() => const GpsWalkSession(
    points: [],
    status: GpsWalkStatus.idle,
    distanceMeters: 0,
    perimeterMeters: 0,
    areaSquareMeters: 0,
    isAutoMode: true,
  );

  /// Alias de pode fechar: liga o início ao fim (≥ 3 pontos).
  bool get canFinish => points.length >= 3;

  /// `true` se há pontos suficientes para parar sem fechar (≥ 2).
  bool get canStopOpen => points.length >= 2;

  /// Área em hectares (conveniência de exibição).
  double get areaHectares => areaSquareMeters / 10000.0;

  GpsWalkSession copyWith({
    List<LatLng>? points,
    GpsWalkStatus? status,
    double? distanceMeters,
    double? perimeterMeters,
    double? areaSquareMeters,
    bool? isAutoMode,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return GpsWalkSession(
      points: points ?? this.points,
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      perimeterMeters: perimeterMeters ?? this.perimeterMeters,
      areaSquareMeters: areaSquareMeters ?? this.areaSquareMeters,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  String toString() =>
      'GpsWalkSession(status: $status, points: ${points.length}, '
      'distance: ${distanceMeters.toStringAsFixed(1)}m, '
      'area: ${areaSquareMeters.toStringAsFixed(1)}m², '
      'autoMode: $isAutoMode)';
}
