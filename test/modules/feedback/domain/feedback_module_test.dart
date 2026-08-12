import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/feedback/domain/entities/feedback_module.dart';

void main() {
  group('FeedbackModule.fromLabel', () {
    test('resolve rótulos em português do dashboard', () {
      expect(
        FeedbackModule.fromLabel('Visitas'),
        FeedbackModule.visits,
      );
      expect(
        FeedbackModule.fromLabel('Configurações/Login'),
        FeedbackModule.settingsLogin,
      );
    });

    test('retorna other para valor desconhecido', () {
      expect(FeedbackModule.fromLabel('Desconhecido'), FeedbackModule.other);
      expect(FeedbackModule.fromLabel(null), FeedbackModule.other);
    });
  });
}
