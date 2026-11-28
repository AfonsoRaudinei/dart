import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/fotos_resultado_picker_widget.dart';

class _Host extends StatefulWidget {
  final List<String> inicial;
  final Future<String?> Function(BuildContext) upload;
  final void Function(List<String>)? onChange;

  const _Host({required this.inicial, required this.upload, this.onChange});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<String> urls = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FotosResultadoPickerWidget(
            urls: urls,
            uploadFoto: widget.upload,
            onChanged: (novas) {
              widget.onChange?.call(novas);
              setState(() => urls = novas);
            },
          ),
        ),
      ),
    );
  }
}

List<String> _urls(int n) => [for (var i = 1; i <= n; i++) 'https://x/$i.jpg'];

Finder _miniaturas() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey &&
      '${(w.key as ValueKey).value}'.startsWith('fotos-resultado-miniatura-'),
);

const _adicionar = ValueKey('fotos-resultado-adicionar');

void main() {
  testWidgets('vazio: tile obrigatório, 0/5 e nenhuma miniatura', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(inicial: const [], upload: (_) async => null),
    );

    expect(find.text('Obrigatória'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(_miniaturas(), findsNothing);
  });

  testWidgets('N fotos: N miniaturas, contador N/5 e sem "Obrigatória"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(3), upload: (_) async => null),
    );

    expect(_miniaturas(), findsNWidgets(3));
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Obrigatória'), findsNothing);
    expect(find.byKey(_adicionar), findsOneWidget);
  });

  testWidgets('adicionar anexa a URL devolvida pelo upload', (tester) async {
    List<String>? emitido;
    await tester.pumpWidget(
      _Host(
        inicial: _urls(1),
        upload: (_) async => 'https://x/nova.jpg',
        onChange: (l) => emitido = l,
      ),
    );

    await tester.tap(find.byKey(_adicionar));
    await tester.pumpAndSettle();

    expect(emitido, ['https://x/1.jpg', 'https://x/nova.jpg']);
    expect(_miniaturas(), findsNWidgets(2));
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('upload cancelado (null) não altera a lista', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _Host(
        inicial: _urls(1),
        upload: (_) async => null,
        onChange: (_) => chamado = true,
      ),
    );

    await tester.tap(find.byKey(_adicionar));
    await tester.pumpAndSettle();

    expect(chamado, isFalse);
    expect(_miniaturas(), findsOneWidget);
  });

  testWidgets('mostra loading durante o upload', (tester) async {
    final completer = Completer<String?>();
    await tester.pumpWidget(
      _Host(inicial: _urls(1), upload: (_) => completer.future),
    );

    await tester.tap(find.byKey(_adicionar));
    await tester.pump();

    expect(find.text('Enviando foto...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete('https://x/nova.jpg');
    await tester.pumpAndSettle();

    expect(find.text('Enviando foto...'), findsNothing);
    expect(_miniaturas(), findsNWidgets(2));
  });

  testWidgets('falha no upload mostra mensagem e mantém a lista', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(1), upload: (_) async => throw Exception('falha')),
    );

    await tester.tap(find.byKey(_adicionar));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Não foi possível enviar a foto. Tente novamente.'),
      findsOneWidget,
    );
    expect(_miniaturas(), findsOneWidget);
  });

  testWidgets('remover pede confirmação; cancelar mantém a foto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(2), upload: (_) async => null),
    );

    await tester.tap(find.byKey(const ValueKey('fotos-resultado-remover-0')));
    await tester.pumpAndSettle();
    expect(find.text('Remover foto?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(_miniaturas(), findsNWidgets(2));
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('remover confirmado tira só a foto escolhida', (tester) async {
    List<String>? emitido;
    await tester.pumpWidget(
      _Host(
        inicial: _urls(3),
        upload: (_) async => null,
        onChange: (l) => emitido = l,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fotos-resultado-remover-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(emitido, ['https://x/1.jpg', 'https://x/3.jpg']);
    expect(_miniaturas(), findsNWidgets(2));
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('removeu a única foto: volta ao estado obrigatório', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(1), upload: (_) async => null),
    );

    await tester.tap(find.byKey(const ValueKey('fotos-resultado-remover-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Obrigatória'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('com 5 fotos o tile de adicionar some', (tester) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(5), upload: (_) async => null),
    );

    expect(_miniaturas(), findsNWidgets(5));
    expect(find.byKey(_adicionar), findsNothing);
    expect(find.text('5/5'), findsOneWidget);
  });

  testWidgets('adicionar a 5ª foto esconde o tile', (tester) async {
    await tester.pumpWidget(
      _Host(inicial: _urls(4), upload: (_) async => 'https://x/5.jpg'),
    );

    await tester.tap(find.byKey(_adicionar));
    await tester.pumpAndSettle();

    expect(_miniaturas(), findsNWidgets(5));
    expect(find.byKey(_adicionar), findsNothing);
  });
}
