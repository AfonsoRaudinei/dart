import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/data/services/mercadopago_service.dart';
import 'package:soloforte_app/modules/planos/presentation/screens/confirmacao_screen.dart';
import 'package:soloforte_app/modules/planos/presentation/screens/pagamento_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'MercadoPagoService bloqueia checkout antes de chamar backend no iOS',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final service = MercadoPagoService(
        SupabaseClient('https://example.supabase.co', 'test-anon-key'),
      );

      await expectLater(
        service.criarPreferenciaPagamento(plano: 'bronze', metodo: 'pix'),
        throwsA(isA<UnsupportedError>()),
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('PagamentoScreen não exibe ação de compra no iOS', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      const MaterialApp(home: PagamentoScreen(plano: 'bronze')),
    );

    expect(find.text('Pagamento indisponível'), findsOneWidget);
    expect(find.text('Continuar para pagamento'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('PagamentoScreen não exibe ação de compra no Android', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      const MaterialApp(home: PagamentoScreen(plano: 'bronze')),
    );

    expect(find.text('Pagamento indisponível'), findsOneWidget);
    expect(find.text('Continuar para pagamento'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ConfirmacaoScreen não abre checkout no iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmacaoScreen(
          plano: 'bronze',
          checkoutUrl: 'https://example.com/checkout',
        ),
      ),
    );

    expect(find.text('Confirmação indisponível'), findsOneWidget);
    expect(find.text('Aguardando confirmação do pagamento...'), findsNothing);
    expect(find.text('Plano ativado! 🎉'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
