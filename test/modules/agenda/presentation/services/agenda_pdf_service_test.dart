import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/presentation/services/agenda_pdf_service.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final weekStart = DateTime(2026, 11, 16);
  final events = [
    Event(
      id: 'event-1',
      tipo: EventType.visitaTecnica,
      clienteId: 'client-1',
      titulo: 'Monitoramento',
      dataInicioPlanejada: DateTime(2026, 11, 18, 8),
      dataFimPlanejada: DateTime(2026, 11, 18, 9),
      status: EventStatus.agendado,
      createdAt: DateTime(2026, 11, 15),
      updatedAt: DateTime(2026, 11, 15),
    ),
  ];

  Future<Uint8List> readAsset(String asset) => File(asset).readAsBytes();

  int imageCount(Uint8List pdf) {
    final text = String.fromCharCodes(pdf);
    return RegExp(r'/Subtype\s*/Image').allMatches(text).length;
  }

  test('PDF da agenda leva logo e QR Code de download no rodapé', () async {
    final service = AgendaPdfService(
      const _FakeClientLookup(),
      null,
      readAsset,
    );

    final pdf = await service.generateWeekPdf(events, weekStart);
    final pdfSemQr = await AgendaPdfService(
      const _FakeClientLookup(),
      null,
      _semQr(readAsset),
    ).generateWeekPdf(events, weekStart);
    final text = String.fromCharCodes(pdf);

    expect(imageCount(pdf), greaterThan(imageCount(pdfSemQr)));
    expect(text, contains(RelatorioHtmlRenderer.soloForteAppStoreUrl));
  });

  test('sem o QR Code o PDF ainda sai, só com o logo', () async {
    final service = AgendaPdfService(
      const _FakeClientLookup(),
      null,
      _semQr(readAsset),
    );

    final pdf = await service.generateWeekPdf(events, weekStart);

    expect(imageCount(pdf), greaterThan(0));
    expect(
      String.fromCharCodes(pdf),
      isNot(contains(RelatorioHtmlRenderer.soloForteAppStoreUrl)),
    );
  });
}

AgendaPdfAssetLoader _semQr(AgendaPdfAssetLoader base) {
  return (asset) async {
    if (asset == RelatorioHtmlRenderer.soloForteQrAsset) {
      throw StateError('QR indisponível');
    }
    return base(asset);
  };
}

class _FakeClientLookup implements IClientLookup {
  const _FakeClientLookup();

  @override
  Future<ClientSummary?> findById(String id) async {
    return const ClientSummary(
      id: 'client-1',
      name: 'Cliente Real',
      active: true,
    );
  }

  @override
  Future<List<ClientSummary>> listAtivos() async {
    return const [
      ClientSummary(id: 'client-1', name: 'Cliente Real', active: true),
    ];
  }
}
