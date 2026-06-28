import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';

void main() {
  test('climaRadarEnabledProvider persiste toggle em SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(climaRadarEnabledProvider), isFalse);

    container.read(climaRadarEnabledProvider.notifier).setEnabled(true);
    expect(container.read(climaRadarEnabledProvider), isTrue);
    expect(
      preferencesService.getBool(climaRadarEnabledPreferenceKey),
      isTrue,
    );

    final restored = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
      ],
    );
    addTearDown(restored.dispose);

    expect(restored.read(climaRadarEnabledProvider), isTrue);
  });
}
