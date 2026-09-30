import 'package:flutter_test/flutter_test.dart';
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
}
