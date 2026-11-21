import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../modules/drawing/domain/models/campo_test_photo_draft.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';
import '../../../modules/marketing/domain/entities/campo_teste_case_seed.dart';

/// Aba da ficha que pediu o desenho do campo de teste.
enum CampoTesteCaseKind { resultado, avaliacao }

/// Pedido em aberto enquanto o polígono ainda não foi salvo.
class CampoTesteCaseResume {
  const CampoTesteCaseResume({
    required this.kind,
    required this.fallbackPosition,
  });

  final CampoTesteCaseKind kind;
  final LatLng fallbackPosition;
}

/// Save concluído: o mapa reabre a ficha com [seed].
class CampoTesteCaseOpenRequest {
  const CampoTesteCaseOpenRequest({
    required this.kind,
    required this.position,
    required this.seed,
  });

  final CampoTesteCaseKind kind;
  final LatLng position;
  final CampoTesteCaseSeed seed;
}

final campoTesteCaseResumeProvider = StateProvider<CampoTesteCaseResume?>(
  (ref) => null,
);

final campoTesteCaseOpenRequestProvider =
    StateProvider<CampoTesteCaseOpenRequest?>((ref) => null);

/// Se o save é o polígono pedido pela ficha, pede a reabertura com os dados.
void queueCampoTesteCaseReopen(
  WidgetRef ref,
  DrawingFeature? feature, {
  CampoTestPhotoDraft? campoTestPhoto,
}) {
  final resume = ref.read(campoTesteCaseResumeProvider);
  if (resume == null || feature?.properties.tipo != DrawingType.teste) {
    return;
  }
  final saved = feature!;
  ref.read(campoTesteCaseResumeProvider.notifier).state = null;
  final geo = resolveCampoTestSketchGeo(saved.geometry);
  ref.read(campoTesteCaseOpenRequestProvider.notifier).state =
      CampoTesteCaseOpenRequest(
        kind: resume.kind,
        position: geo ?? resume.fallbackPosition,
        seed: CampoTesteCaseSeed(
          drawingId: saved.id,
          nome: saved.properties.nome,
          areaHa: saved.properties.areaHa,
          clienteId: saved.properties.clienteId,
          fazendaNome: saved.properties.grupo,
          photoPath: campoTestPhoto?.localPath,
        ),
      );
}
