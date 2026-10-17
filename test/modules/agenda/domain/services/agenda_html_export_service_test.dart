import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/services/agenda_html_export_service.dart';

String _between(String html, String start, String end) {
  final from = html.indexOf(start);
  expect(from, greaterThanOrEqualTo(0), reason: 'faltou $start');
  final to = html.indexOf(end, from + start.length);
  expect(to, greaterThan(from), reason: 'faltou $end');
  return html.substring(from, to);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'agenda exportada: marca só no rodapé, header sem slot de logo',
    () async {
      final event = Event(
        id: 'e1',
        tipo: EventType.visitaTecnica,
        clienteId: 'c1',
        titulo: 'Visita tecnica',
        dataInicioPlanejada: DateTime(2026, 7, 7, 8),
        dataFimPlanejada: DateTime(2026, 7, 7, 10),
        status: EventStatus.agendado,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
        syncStatus: 'pending',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );

      final html = await AgendaHtmlExportService().export(
        events: [event],
        clientes: const {
          'c1': ClientSummary(id: 'c1', name: 'Cliente Teste', active: true),
        },
        oportunidades: const {},
        periodoLabel: 'Semana 28',
        consultantName: 'Agronomo Teste',
      );

      final header = _between(html, '<div class="hdr">', '<div class="sum">');
      expect(header, contains('Agenda de Visitas'));
      expect(header, isNot(contains('class="brand"')));
      expect(header, isNot(contains('<img')));
      expect(header, isNot(contains('SoloForte')));
      expect(header, isNot(contains(RegExp(r'<div[^>]*>\s*</div>'))));
      expect(html, isNot(contains('.brand{')));
      expect(html, isNot(contains('logo-img')));

      final footer = _between(html, '<div class="ftr">', '</body>');
      expect(
        footer,
        contains(RegExp(r'class="sf-brand-logo" src="data:image/png;base64,')),
      );
      expect(footer, contains('<strong>SoloForte</strong>'));
      expect(footer, isNot(contains('Agronomo Teste')));
      expect(footer, isNot(contains('Responsável')));
      expect(html, contains('Cliente Teste'));
    },
  );
}
