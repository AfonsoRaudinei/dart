import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Blindagem do asset compartilhável: nenhum sinal de confiança pode ser
/// fabricado, porque `MarketingCase` não tem nota, avaliação nem verificação.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String story;

  setUpAll(() async {
    story = await rootBundle.loadString('assets/story.html');
  });

  test('story nao exibe nota, estrelas nem selo de verificacao', () {
    expect(story, isNot(contains('class="star"')));
    expect(story, isNot(contains('review-score')));
    expect(story, isNot(contains('review-verified')));
    expect(story, isNot(contains('Verificado')));
    expect(story, isNot(contains('/ 5,0')));
    expect(story, isNot(contains('Excelente')));
  });

  test('story nao atribui o texto tecnico como avaliacao do produtor', () {
    expect(story, isNot(contains('Avaliação do Produtor')));
    expect(story, contains('Conclusão Técnica'));
  });

  test('story nao inventa cargo do responsavel', () {
    expect(story, isNot(contains('Agrônoma')));
    expect(story, isNot(contains('Agrônomo')));
  });
}
