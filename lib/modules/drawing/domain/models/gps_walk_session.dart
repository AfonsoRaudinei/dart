import 'package:latlong2/latlong.dart';

/// Status do ciclo de vida de uma sessão de medição GPS Walk.
enum GpsWalkStatus {
  /// Modo selecionado mas medição ainda não iniciada.
  idle,

  /// Coleta de pontos GPS ativa.
  measuring,

  /// Coleta suspensa temporariamente; pontos preservados.
  paused,

  /// Sessão concluída; geometria enviada ao DrawingController.
  finished,
}

/// Estado imutável de uma sessão de medição GPS Walk.
///
/// Representa o ciclo completo de coleta de pontos GPS em campo:
/// idle → measuring → paused → measuring → finished
///
/// ### Responsabilidades
/// - Armazenar pontos coletados (espelho de DrawingController.gpsVertices)
/// - Armazenar métricas calculadas em tempo real (perímetro + área)
/// - Rastrear modo de coleta (automático vs manual)
///
/// ### Imutabilidade
/// Toda mutação cria uma nova instância via [copyWith].
/// Fonte da verdade durante sessão: estado em memória.
/// Ao finalizar, geometria é transferida ao DrawingController.
///
/// ### Validação
/// Mínimo de 3 pontos para habilitar conclusão (checado no notifier/UI).
class GpsWalkSession {
  /// Pontos GPS aceitos durante a sessão.
  final List<LatLng> points;

  /// Status atual da sessão.
  final GpsWalkStatus status;

  /// Perímetro calculado em tempo real (metros).
  final double perimeterMeters;

  /// Área calculada em tempo real (metros quadrados).
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
    this.isAutoMode = true,
    this.startedAt,
    this.finishedAt,
  });

  /// Estado inicial: nenhum ponto, modo idle, coleta automática.
  factory GpsWalkSession.initial() => const GpsWalkSession(
        points: [],
        status: GpsWalkStatus.idle,
        perimeterMeters: 0,
        areaSquareMeters: 0,
        isAutoMode: true,
      );

  /// `true` se há pontos suficientes para concluir o polígono.
  bool get canFinish => points.length >= 3;

  /// Área em hectares (conveniência de exibição).
  double get areaHectares => areaSquareMeters / 10000.0;

  GpsWalkSession copyWith({
    List<LatLng>? points,
    GpsWalkStatus? status,
    double? perimeterMeters,
    double? areaSquareMeters,
    bool? isAutoMode,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return GpsWalkSession(
      points: points ?? this.points,
      status: status ?? this.status,
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
      'perimeter: ${perimeterMeters.toStringAsFixed(1)}m, '
      'area: ${areaSquareMeters.toStringAsFixed(1)}m², '
      'autoMode: $isAutoMode)';
}
