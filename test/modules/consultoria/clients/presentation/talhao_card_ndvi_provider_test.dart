import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/talhao_card_ndvi_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('talhaoCardNdviEnabledProvider lê modo NDVI persistido por fieldId', () async {
    SharedPreferences.setMockInitialValues({
      'consultoria_talhao_card_ndvi_field-a': true,
    });
    final shared = await SharedPreferences.getInstance();
    final prefs = PreferencesService(shared);

    final container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
    );

    expect(container.read(talhaoCardNdviEnabledProvider('field-a')), isTrue);
    expect(container.read(talhaoCardNdviEnabledProvider('field-b')), isFalse);

    container.dispose();
  });
}
