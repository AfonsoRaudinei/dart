import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/relatorio_tecnico.dart';

class RelatorioPdfService {
  /// Gera o documento PDF a partir da entidade RelatorioTecnico.
  /// Retorna os bytes do PDF prontos para share ou save.
  static Future<List<int>> generate(RelatorioTecnico relatorio) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(relatorio),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInfoSection(relatorio),
          pw.SizedBox(height: 16),
          if (relatorio.talhoes.isNotEmpty) _buildTalhoesSection(relatorio),
          pw.SizedBox(height: 16),
          if (relatorio.ocorrencias.isNotEmpty) _buildOcorrenciasSection(relatorio),
          pw.SizedBox(height: 16),
          if (relatorio.customNotes?.isNotEmpty == true)
            _buildNotesSection(relatorio),
        ],
      ),
    );

    return pdf.save();
  }

  // --- SEÇÕES ---

  static pw.Widget _buildHeader(RelatorioTecnico r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Relatório de Visita Técnica',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(r.farmName,
            style: const pw.TextStyle(fontSize: 13)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildInfoSection(RelatorioTecnico r) {
    return pw.Table(
      children: [
        _tableRow('Período', '${_formatDate(r.periodStart)} — ${_formatDate(r.periodEnd)}'),
        _tableRow('Fazenda', r.farmName),
        _tableRow('Status', r.status.name),
      ],
    );
  }

  static pw.TableRow _tableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ),
    ]);
  }

  static pw.Widget _buildTalhoesSection(RelatorioTecnico r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Talhões Visitados',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...r.talhoes.map((t) {
          final props = [
            if (t.areaHectares != null) '${t.areaHectares} ha',
            if (t.cultura != null) t.cultura,
            if (t.safra != null) t.safra,
          ];
          final details = props.isNotEmpty ? ' (${props.join(', ')})' : '';
          return pw.Text('• ${t.nomeTalhao}$details',
            style: const pw.TextStyle(fontSize: 10));
        }),
      ],
    );
  }

  static pw.Widget _buildOcorrenciasSection(RelatorioTecnico r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ocorrências Registradas',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...r.ocorrencias.map((o) => pw.Text('• [${o.tipo}] ${o.descricao}',
            style: const pw.TextStyle(fontSize: 10))),
      ],
    );
  }

  static pw.Widget _buildNotesSection(RelatorioTecnico r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Observações',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(r.customNotes ?? '',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Gerado pelo SoloForte',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final localDt = dt.toLocal();
    return '${localDt.day.toString().padLeft(2, '0')}/'
        '${localDt.month.toString().padLeft(2, '0')}/'
        '${localDt.year}';
  }
}
