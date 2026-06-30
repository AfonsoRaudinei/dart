import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
          PopupMenuButton<ReportExportFormat>(
            tooltip: 'Exportar dados',
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: _export,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ReportExportFormat.pdf,
                child: Text('Exportar PDF'),
              ),
              const PopupMenuItem(
                value: ReportExportFormat.html,
                child: Text('Exportar HTML'),
              ),
              if (widget.jsonData != null)
                const PopupMenuItem(
                  value: ReportExportFormat.json,
                  child: Text('Exportar JSON'),
                ),
              if (widget.csvData != null)
                const PopupMenuItem(
                  value: ReportExportFormat.csv,
                  child: Text('Exportar CSV'),
                ),
            ],
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

  Future<void> _export(ReportExportFormat format) async {
    try {
      await widget.exportService.export(
        format,
        ReportExportPayload(
          title: widget.title,
          html: widget.htmlContent,
          fileBaseName: widget.fileBaseName,
          json: widget.jsonData,
          csv: widget.csvData,
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
