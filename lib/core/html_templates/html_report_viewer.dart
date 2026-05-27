import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  const HtmlReportViewer({
    super.key,
    required this.title,
    required this.htmlContent,
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
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar',
            onPressed: _shareHtml,
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

  Future<void> _exportPdf() async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          // ignore: deprecated_member_use
          return Printing.convertHtml(format: format, html: widget.htmlContent);
        },
        name: widget.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    }
  }

  Future<void> _shareHtml() async {
    try {
      final dir = await getTemporaryDirectory();
      final safe = widget.title
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      final file = File('${dir.path}/$safe.html');
      await file.writeAsString(widget.htmlContent);
      await Share.shareXFiles([XFile(file.path)], subject: widget.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
      }
    }
  }
}
