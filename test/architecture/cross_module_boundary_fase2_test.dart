import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map nao importa consultoria nem ndvi diretamente', () {
    final file = File(
      'lib/modules/map/presentation/widgets/visit_active_card.dart',
    );
    final content = file.readAsStringSync();
    expect(content.contains('modules/consultoria/'), isFalse);
    expect(content.contains('modules/ndvi/'), isFalse);
    expect(content.contains('i_visit_client_lookup_provider'), isTrue);
    expect(content.contains('i_ndvi_field_presenter_provider'), isTrue);
  });

  test('agenda_ai nao importa agenda nem carteira diretamente', () {
    final file = File(
      'lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart',
    );
    final content = file.readAsStringSync();
    expect(content.contains('modules/agenda/'), isFalse);
    expect(content.contains('modules/carteira/'), isFalse);
    expect(content.contains('agendaAiRecommendationContextLookupProvider'), isTrue);
    expect(content.contains('agendaAiVisitWriterProvider'), isTrue);
  });

  test('consultoria field_detail nao importa ndvi diretamente', () {
    final file = File(
      'lib/modules/consultoria/clients/presentation/screens/field_detail_screen.dart',
    );
    final content = file.readAsStringSync();
    expect(content.contains('modules/ndvi/'), isFalse);
    expect(content.contains('ndviLatestLookupProvider'), isTrue);
    expect(content.contains('ndviFieldPresenterProvider'), isTrue);
  });
}
