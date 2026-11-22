import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_farm_lookup.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../domain/entities/event.dart';

/// Lê os bytes de um asset do app. Testes injetam um fake.
typedef AgendaPdfAssetLoader = Future<Uint8List> Function(String asset);

Future<Uint8List> loadBundledAgendaPdfAsset(String asset) async {
  final data = await rootBundle.load(asset);
  return data.buffer.asUint8List();
}

/// PDF secundário do planejamento semanal (HTML é o caminho principal).
///
/// Branding alinhado ao designer: Samsung/navy; rodapé com logo SoloForte e
/// QR Code de download do app, como nos relatórios HTML.
class AgendaPdfService {
  final IClientLookup _clientLookup;
  final IFarmLookup? _farmLookup;
  final AgendaPdfAssetLoader _assetLoader;

  static const _logoAsset = RelatorioHtmlRenderer.soloForteLogoAsset;
  static const _qrAsset = RelatorioHtmlRenderer.soloForteQrAsset;
  static final _samsung = PdfColor.fromHex('1428A0');
  static final _navy = PdfColor.fromHex('2C5564');

  const AgendaPdfService(
    this._clientLookup, [
    this._farmLookup,
    this._assetLoader = loadBundledAgendaPdfAsset,
  ]);

  Future<pw.MemoryImage?> _loadImage(String asset) async {
    try {
      return pw.MemoryImage(await _assetLoader(asset));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> generateWeekPdf(
    List<Event> events,
    DateTime weekStart,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 6));

    final filtered =
        events.where((e) {
          if (e.syncStatus == 'deleted' || e.syncStatus == 'deleted_local') {
            return false;
          }
          final d = e.dataInicioPlanejada;
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        }).toList()..sort(
          (a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada),
        );

    final clientIds = filtered.map((e) => e.clienteId).toSet();
    final clientNames = <String, String>{};
    await Future.wait(
      clientIds.map((id) async {
        try {
          final c = await _clientLookup.findById(id);
          clientNames[id] = c?.name ?? '—';
        } catch (_) {
          clientNames[id] = '—';
        }
      }),
    );

    final farmIds = filtered
        .map((e) => e.fazendaId)
        .whereType<String>()
        .toSet();
    final farmNames = <String, String>{};
    if (_farmLookup != null && farmIds.isNotEmpty) {
      await Future.wait(
        farmIds.map((id) async {
          try {
            final f = await _farmLookup.findById(id);
            farmNames[id] =
                f?.name ??
                'Fazenda: ${id.substring(0, id.length.clamp(0, 8))}…';
          } catch (_) {
            farmNames[id] =
                'Fazenda: ${id.substring(0, id.length.clamp(0, 8))}…';
          }
        }),
      );
    } else {
      for (final id in farmIds) {
        farmNames[id] = 'Fazenda: ${id.substring(0, id.length.clamp(0, 8))}…';
      }
    }

    final byDay = <DateTime, List<Event>>{};
    for (var i = 0; i < 7; i++) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      byDay[day] = [];
    }
    for (final event in filtered) {
      final d = event.dataInicioPlanejada;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key]?.add(event);
    }

    final logoImage = await _loadImage(_logoAsset);
    final qrImage = await _loadImage(_qrAsset);

    final doc = pw.Document();
    final ptBR = DateFormat.yMMMMd('pt_BR');
    final timeFormat = DateFormat('HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(weekStart, weekEnd),
        footer: (_) => _buildFooter(logoImage, qrImage),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          ..._buildDays(byDay, clientNames, farmNames, ptBR, timeFormat),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(DateTime weekStart, DateTime weekEnd) {
    final fmt = DateFormat('d MMM', 'pt_BR');
    final fmtYear = DateFormat('d MMM yyyy', 'pt_BR');
    final periodo = '${fmt.format(weekStart)} – ${fmtYear.format(weekEnd)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SoloForte',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _samsung,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Planejamento Semanal',
                  style: pw.TextStyle(fontSize: 13, color: _navy),
                ),
              ],
            ),
            pw.Text(
              periodo,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.5, color: _samsung),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _buildFooter(pw.MemoryImage? logoImage, pw.MemoryImage? qrImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            if (logoImage != null) ...[
              pw.Image(logoImage, width: 16, height: 16),
              pw.SizedBox(width: 8),
            ],
            pw.Text(
              'SoloForte',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ],
        ),
        if (qrImage != null)
          pw.UrlLink(
            destination: RelatorioHtmlRenderer.soloForteAppStoreUrl,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Image(qrImage, width: 44, height: 44),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Baixe o SoloForte',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<pw.Widget> _buildDays(
    Map<DateTime, List<Event>> byDay,
    Map<String, String> clientNames,
    Map<String, String> farmNames,
    DateFormat ptBR,
    DateFormat timeFormat,
  ) {
    final widgets = <pw.Widget>[];

    for (final entry in byDay.entries) {
      final day = entry.key;
      final dayEvents = entry.value;
      final weekday = DateFormat('EEEE', 'pt_BR').format(day).toUpperCase();
      final dateLabel = DateFormat('d MMM yyyy', 'pt_BR').format(day);

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8EEF8'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    weekday,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _samsung,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    dateLabel,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            if (dayEvents.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, top: 2, bottom: 4),
                child: pw.Text(
                  'Nenhum evento agendado',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              ...dayEvents.map(
                (e) => _buildEventRow(e, clientNames, farmNames, timeFormat),
              ),
          ],
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            'Nenhum evento nesta semana.',
            style: const pw.TextStyle(color: PdfColors.grey600),
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildEventRow(
    Event event,
    Map<String, String> clientNames,
    Map<String, String> farmNames,
    DateFormat timeFormat,
  ) {
    final inicio = timeFormat.format(event.dataInicioPlanejada);
    final fim = timeFormat.format(event.dataFimPlanejada);
    final clienteNome = clientNames[event.clienteId] ?? '—';
    final fazendaNome = event.fazendaId != null
        ? (farmNames[event.fazendaId!] ?? '—')
        : '—';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            event.titulo,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          _infoRow('Tipo', '${event.tipo.label} · $inicio – $fim'),
          _infoRow('Cliente', clienteNome),
          _infoRow('Fazenda', fazendaNome),
          _infoRow('Status', event.status.label),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }
}
