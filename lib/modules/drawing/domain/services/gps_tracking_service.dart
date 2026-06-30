import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_logger.dart';
import '../drawing_utils.dart';
import '../models/drawing_models.dart';

// ─── Constantes de qualidade GPS ─────────────────────────────────────────────
/// Precisão máxima aceitável em metros (descarta pontos com pior precisão)
const double kGpsMaxAccuracyM = 15.0;

/// Distância mínima entre vértices aceitos (evita pontos duplicados)
const double kGpsMinSegmentM = 5.0;

/// Mínimo de vértices distintos para fechar o polígono
const int kGpsMinVertices = 3;
// ─────────────────────────────────────────────────────────────────────────────

/// Qualidade do sinal GPS exibida no overlay de rastreamento.
enum GpsQuality {
  /// Precisão < 5 m — excelente para campo
  excellent,

  /// Precisão entre 5 m e [kGpsMaxAccuracyM] — aceitável
  acceptable,

  /// Precisão > [kGpsMaxAccuracyM] — ponto será descartado
  poor,
}

/// Resultado imutável de uma operação GPS (adicionar ou descartar vértice).
class GpsTrackingResult {
  /// Lista de vértices aceitos após a operação (pode ser idêntica à entrada se
  /// o ponto foi descartado).
  final List<LatLng> vertices;

  /// Precisão do ponto GPS recebido, em metros.
  final double? lastAccuracyM;

  /// `true` se o ponto foi adicionado à lista; `false` se descartado.
  final bool accepted;

  /// Motivo do descarte quando [accepted] == `false`.
  final String? discardReason;

  const GpsTrackingResult({
    required this.vertices,
    this.lastAccuracyM,
    this.accepted = true,
    this.discardReason,
  });
}

/// Serviço puro de rastreamento GPS para desenho de talhão caminhando o
/// perímetro.
///
/// ### Responsabilidades
/// - Receber eventos de posição GPS via [processPosition]
/// - Filtrar por precisão e distância mínima entre pontos
/// - Acumular vértices aceitos (sem mutação interna de estado)
/// - Construir [DrawingPolygon] fechado ao chamar [finalize]
///
/// ### Ausência de I/O
/// Este serviço não possui streams, timers nem dependências de plataforma.
/// É completamente testável de forma unitária.
/// O stream GPS real é gerenciado pelo `DrawingController` via
/// `LocationService` existente em `dashboard/services/`.
class GpsTrackingService {
  const GpsTrackingService();

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Processa uma nova posição GPS e decide se aceita ou descarta o ponto.
  ///
  /// - [vertices]: lista imutável de vértices aceitos até agora
  /// - [newPoint]: coordenada recebida do GPS
  /// - [accuracyM]: precisão horizontal em metros reportada pelo GPS
  ///
  /// Retorna [GpsTrackingResult] com a lista (possivelmente) atualizada e o
  /// status do ponto.
  GpsTrackingResult processPosition({
    required List<LatLng> vertices,
    required LatLng newPoint,
    required double accuracyM,
  }) {
    // Filtro 1 — precisão abaixo do limiar
    if (accuracyM > kGpsMaxAccuracyM) {
      AppLogger.debug(
        'GPS: ponto descartado — precisao ${accuracyM.toStringAsFixed(1)}m > ${kGpsMaxAccuracyM}m',
        tag: 'GpsTrackingService',
      );
      return GpsTrackingResult(
        vertices: vertices,
        lastAccuracyM: accuracyM,
        accepted: false,
        discardReason:
            'Precisao insuficiente (${accuracyM.toStringAsFixed(0)}m)',
      );
    }

    // Filtro 2 — distância mínima entre vértices consecutivos
    if (vertices.isNotEmpty) {
      final distM = _haversineM(vertices.last, newPoint);
      if (distM < kGpsMinSegmentM) {
        return GpsTrackingResult(
          vertices: vertices,
          lastAccuracyM: accuracyM,
          accepted: false,
          discardReason:
              'Muito proximo do ultimo ponto (${distM.toStringAsFixed(0)}m)',
        );
      }
    }

    final updated = [...vertices, newPoint];
    AppLogger.debug(
      'GPS: vertice #${updated.length} aceito — precisao ${accuracyM.toStringAsFixed(1)}m',
      tag: 'GpsTrackingService',
    );
    return GpsTrackingResult(
      vertices: updated,
      lastAccuracyM: accuracyM,
      accepted: true,
    );
  }

  /// Remove o último vértice da lista (desfazer em campo).
  ///
  /// Retorna a lista sem o último elemento, ou a mesma lista se já vazia.
  List<LatLng> undoLastVertex(List<LatLng> vertices) {
    if (vertices.isEmpty) return vertices;
    return vertices.sublist(0, vertices.length - 1);
  }

  /// Converte os vértices coletados em um [DrawingPolygon] fechado.
  ///
  /// Retorna `null` se houver menos de [kGpsMinVertices] vértices.
  DrawingPolygon? finalize(List<LatLng> vertices) {
    if (vertices.length < kGpsMinVertices) return null;

    // Converter para anel GeoJSON: [[lng, lat], ...]
    final ring = vertices
        .map((p) => <double>[p.longitude, p.latitude])
        .toList();

    // GeoJSON exige que o primeiro e último pontos sejam iguais
    final first = ring.first;
    final last = ring.last;
    if ((first[0] - last[0]).abs() > 1e-9 ||
        (first[1] - last[1]).abs() > 1e-9) {
      ring.add(List<double>.from(first));
    }

    final polygon = DrawingPolygon(coordinates: [ring]);

    // Normalizar e simplificar para remover artefatos de GPS
    final normalized = DrawingUtils.normalizeGeometry(polygon);
    final simplified = DrawingUtils.simplifyGeometry(normalized);

    return simplified is DrawingPolygon ? simplified : polygon;
  }

  /// Classifica a qualidade do sinal GPS para exibição no overlay.
  GpsQuality classifyAccuracy(double accuracyM) {
    if (accuracyM < 5.0) return GpsQuality.excellent;
    if (accuracyM <= kGpsMaxAccuracyM) return GpsQuality.acceptable;
    return GpsQuality.poor;
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Calcula a distância entre dois pontos usando a formula Haversine.
  /// Resultado em metros.
  double _haversineM(LatLng a, LatLng b) {
    const earthRadiusM = 6371000.0;
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);

    final sinHalfDLat = math.sin(dLat / 2);
    final sinHalfDLng = math.sin(dLng / 2);

    final h = sinHalfDLat * sinHalfDLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfDLng * sinHalfDLng;

    return 2 * earthRadiusM * math.asin(math.sqrt(h));
  }

  double _toRad(double degrees) => degrees * math.pi / 180.0;
}
