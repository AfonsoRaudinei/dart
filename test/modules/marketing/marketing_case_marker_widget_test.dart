import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_marker.dart';

void main() {
  group('MarketingCaseMarker', () {
    test('aplica zoom mínimo progressivo por plano', () {
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.ouro, 9.9),
        isFalse,
      );
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.ouro, 10.0),
        isTrue,
      );
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.prata, 11.9),
        isFalse,
      );
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.prata, 12.0),
        isTrue,
      );
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.bronze, 13.9),
        isFalse,
      );
      expect(
        MarketingCaseMarker.isVisibleAtZoom(PlanoMarketing.bronze, 14.0),
        isTrue,
      );
    });

    testWidgets('usa foto depois como imagem principal de Antes/Depois', (
      tester,
    ) async {
      final marketingCase = _case(
        tipo: CaseTipo.antesDepois,
        fotoAntesUrl: 'https://example.com/antes.jpg',
        fotoDepoisUrl: 'https://example.com/depois.jpg',
      );

      await tester.pumpWidget(
        _wrap(MarketingCaseMarker(marketingCase: marketingCase, onTap: () {})),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      expect(image.imageUrl, 'https://example.com/depois.jpg');
    });

    testWidgets('mantem placeholder quando Antes/Depois nao tem fotos', (
      tester,
    ) async {
      final marketingCase = _case(tipo: CaseTipo.antesDepois);

      await tester.pumpWidget(
        _wrap(MarketingCaseMarker(marketingCase: marketingCase, onTap: () {})),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.agriculture), findsOneWidget);
    });

    testWidgets('mostra badge de ROI calculado para Resultado completo', (
      tester,
    ) async {
      final marketingCase = _case(
        tipo: CaseTipo.resultado,
        fotoPrincipalUrl: 'https://example.com/resultado.jpg',
        prodSemProduto: 60,
        prodComProduto: 64,
        unidadeProdutividade: 'sc/ha',
        custoProdutoPorHa: 90,
        valorGrao: 110,
      );

      await tester.pumpWidget(
        _wrap(MarketingCaseMarker(marketingCase: marketingCase, onTap: () {})),
      );

      expect(find.text('ROI R\$350/ha'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

MarketingCase _case({
  required CaseTipo tipo,
  String? fotoPrincipalUrl,
  String? fotoAntesUrl,
  String? fotoDepoisUrl,
  double? prodSemProduto,
  double? prodComProduto,
  String? unidadeProdutividade,
  double? custoProdutoPorHa,
  double? valorGrao,
}) {
  final now = DateTime.utc(2026, 7, 22);
  return MarketingCase(
    id: 'case-1',
    tipo: tipo,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Brejinho',
    produtorFazenda: 'Adriano',
    produtoUtilizado: 'coach',
    dataCase: now,
    fotoPrincipalUrl: fotoPrincipalUrl,
    fotoAntesUrl: fotoAntesUrl,
    fotoDepoisUrl: fotoDepoisUrl,
    prodSemProduto: prodSemProduto,
    prodComProduto: prodComProduto,
    unidadeProdutividade: unidadeProdutividade,
    custoProdutoPorHa: custoProdutoPorHa,
    valorGrao: valorGrao,
    criadoEm: now,
    atualizadoEm: now,
  );
}
