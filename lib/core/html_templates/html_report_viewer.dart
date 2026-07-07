import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/share_position.dart';
import 'report_export_service.dart';

/// Widget genérico para exibir qualquer relatório HTML gerado pelos renderers.
///
/// Uso:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => HtmlReportViewer(
///     title: 'Relatório de Visita',
///     htmlContent: htmlString,
///   ),
/// ));
/// ```
class HtmlReportViewer extends StatefulWidget {
  final String title;
  final String htmlContent;
  final String? fileBaseName;
  final Map<String, dynamic>? jsonData;
  final String? csvData;
  final ReportExportService exportService;

  const HtmlReportViewer({
    super.key,
    required this.title,
    required this.htmlContent,
    this.fileBaseName,
    this.jsonData,
    this.csvData,
    this.exportService = const ReportExportService(),
  });

  @override
  State<HtmlReportViewer> createState() => _HtmlReportViewerState();
}

class _HtmlReportViewerState extends State<HtmlReportViewer> {
  late final WebViewController _controller;
  bool _loading = true;
  final GlobalKey _exportButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C5564),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5564),
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            key: _exportButtonKey,
            tooltip: 'Exportar',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: _exportHtml,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5B935)),
            ),
        ],
      ),
    );
  }

  Future<void> _exportHtml() async {
    try {
      await widget.exportService.export(
        ReportExportFormat.html,
        ReportExportPayload(
          title: widget.title,
          html: widget.htmlContent,
          fileBaseName: widget.fileBaseName,
          json: widget.jsonData,
          csv: widget.csvData,
        ),
        sharePositionOrigin: resolveSharePositionOrigin(
          context,
          anchorKey: _exportButtonKey,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exportação iniciada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      }
    }
  }
}
