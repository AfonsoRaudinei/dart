import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/ui/screens/map/controllers/map_viewport_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('sem usuário o viewport segue GPS', () {
    expect(viewportUsesProducerStrategy(null), isFalse);
  });

  test('produtor encaixa nos talhões', () {
    final user = User.fromJson(const {
      'id': 'produtor-1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'role': 'produtor'},
      'aud': 'authenticated',
      'created_at': '2026-08-16T12:00:00.000Z',
    })!;

    expect(viewportUsesProducerStrategy(user), isTrue);
  });

  test('consultor segue GPS', () {
    final user = User.fromJson(const {
      'id': 'consultor-1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'role': 'consultor'},
      'aud': 'authenticated',
      'created_at': '2026-08-16T12:00:00.000Z',
    })!;

    expect(viewportUsesProducerStrategy(user), isFalse);
  });

  test('produtor com polígono salvo abre na fazenda', () {
    expect(
      resolveOfflineCamera(
        isProducer: true,
        hasStoredFarmPoints: true,
        fieldsLoading: false,
        gpsFixAvailable: false,
      ),
      OfflineCameraChoice.storedFarm,
    );
  });

  test('sem GPS a coordenada da fazenda salva ainda vale', () {
    expect(
      resolveOfflineCamera(
        isProducer: false,
        hasStoredFarmPoints: true,
        fieldsLoading: false,
        gpsFixAvailable: false,
      ),
      OfflineCameraChoice.storedFarm,
    );
  });

  test('consultor com GPS não substitui o fix pela fazenda', () {
    expect(
      resolveOfflineCamera(
        isProducer: false,
        hasStoredFarmPoints: true,
        fieldsLoading: false,
        gpsFixAvailable: true,
      ),
      OfflineCameraChoice.gps,
    );
  });

  test('polígono local vira pontos da câmera', () {
    final fields = [
      Talhao(
        id: 'talhao-1',
        name: 'Talhão 1',
        areaHa: 10,
        crop: '',
        harvest: '',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [-48.0, -15.0],
              [-48.1, -15.0],
              [-48.1, -15.1],
              [-48.0, -15.0],
            ],
          ],
        },
      ),
    ];

    final points = polygonPointsFromFields(fields);
    expect(points, isNotEmpty);
    expect(points.first, const LatLng(-15.0, -48.0));
  });

  test('GPS tardio não move se o talhão já enquadrou', () {
    expect(
      shouldCommitGpsMove(
        viewport: InitialViewportState.applied,
        explicitCameraIntent: false,
      ),
      isFalse,
    );
  });

  test('GPS tardio não move com intent explícito mesmo em idle', () {
    expect(
      shouldCommitGpsMove(
        viewport: InitialViewportState.idle,
        explicitCameraIntent: true,
      ),
      isFalse,
    );
  });

  test('GPS inicial move quando idle e sem intent', () {
    expect(
      shouldCommitGpsMove(
        viewport: InitialViewportState.idle,
        explicitCameraIntent: false,
      ),
      isTrue,
    );
  });

  test('aborted também bloqueia o move GPS', () {
    expect(
      shouldCommitGpsMove(
        viewport: InitialViewportState.aborted,
        explicitCameraIntent: false,
      ),
      isFalse,
    );
  });
}
