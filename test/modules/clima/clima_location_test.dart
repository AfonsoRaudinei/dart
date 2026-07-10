import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_user_location_lookup.dart';
import 'package:soloforte_app/core/contracts/i_user_location_lookup_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';

Future<ProviderContainer> _createContainer({
  required List<Override> overrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  return ProviderContainer(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      ...overrides,
    ],
  );
}

void main() {
  group('climaLocationProvider', () {
    test('cidade IBGE selecionada tem prioridade sobre lookup do mapa', () async {
      final container = await _createContainer(
        overrides: [
          userLocationLookupProvider.overrideWithValue(
            const FakeUserLocationLookup(LatLng(-3.73, -38.52)),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(climaSelectedCityProvider.notifier).state = (
        nome: 'Palmas, TO',
        lat: -10.18,
        lon: -48.33,
      );

      expect(await container.read(climaLocationProvider.future), (
        lat: -10.18,
        lon: -48.33,
      ));
    });

    test('localização manual tem prioridade sobre lookup do mapa', () async {
      final container = await _createContainer(
        overrides: [
          userLocationLookupProvider.overrideWithValue(
            const FakeUserLocationLookup(LatLng(-3.73, -38.52)),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(climaManualLocationProvider.notifier).state = (
        lat: -10.18,
        lon: -48.33,
      );

      expect(await container.read(climaLocationProvider.future), (
        lat: -10.18,
        lon: -48.33,
      ));
    });

    test('lookup do mapa retorna coordenadas quando disponível', () async {
      final container = await _createContainer(
        overrides: [
          userLocationLookupProvider.overrideWithValue(
            const FakeUserLocationLookup(LatLng(-10.18, -48.33)),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(climaLocationProvider.future), (
        lat: -10.18,
        lon: -48.33,
      ));
    });

    // TODO(H3-debt): GPS deniedForever e keys ausentes requerem injecao
    // local de Geolocator e configuracao de APIs (Opcao A).
  });
}

class FakeUserLocationLookup implements IUserLocationLookup {
  const FakeUserLocationLookup(this.position);

  final LatLng? position;

  @override
  LatLng? getUserLatLng() => position;
}
