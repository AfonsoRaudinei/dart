import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/planos/data/services/mercadopago_service.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  test('mercadoPagoServiceProvider resolve MercadoPagoService', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(mercadoPagoServiceProvider);
    expect(service, isA<MercadoPagoService>());
  });
}
