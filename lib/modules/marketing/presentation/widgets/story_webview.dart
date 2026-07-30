import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../domain/entities/marketing_case.dart';
import 'story_html_injector.dart';

/// WebView que carrega `assets/story.html` com dados do [MarketingCase].
class StoryWebView extends StatefulWidget {
  final MarketingCase marketingCase;
  final GlobalKey repaintKey;

  const StoryWebView({
    required this.marketingCase,
    required this.repaintKey,
    super.key,
  });

  @override
  State<StoryWebView> createState() => _StoryWebViewState();
}

class _StoryWebViewState extends State<StoryWebView> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final template = await rootBundle.loadString('assets/story.html');
      final logoSrc = await RelatorioHtmlRenderer.assetImageToBase64(
        RelatorioHtmlRenderer.soloForteLogoAsset,
      );

      final fotoPrincipal = await _fotoParaSrc(
        widget.marketingCase.fotoPrincipalUrl,
      );
      final fotoAntes = await _fotoParaSrc(widget.marketingCase.fotoAntesUrl);
      final fotoDepois = await _fotoParaSrc(widget.marketingCase.fotoDepoisUrl);

      final html = injectStoryData(
        template,
        widget.marketingCase,
        fotoSrc: fotoPrincipal,
        fotoAntesSrc: fotoAntes,
        fotoDepoisSrc: fotoDepois,
        logoSrc: logoSrc,
      );

      if (!mounted) return;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setBackgroundColor(const Color(0xFF0E1117))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadHtmlString(html);

      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar a story.';
      });
    }
  }

  /// Baixa URL remota → data URI; fallback silencioso para a URL original.
  Future<String?> _fotoParaSrc(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('data:')) return trimmed;

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final local = await RelatorioHtmlRenderer.photoPathToBase64(trimmed);
      return local ?? trimmed;
    }

    try {
      final response = await http
          .get(Uri.parse(trimmed))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return 'data:image/jpeg;base64,${base64Encode(response.bodyBytes)}';
      }
    } catch (_) {
      // fallback silencioso
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFF0E1117),
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = _controller;
    return ColoredBox(
      color: const Color(0xFF0E1117),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            RepaintBoundary(
              key: widget.repaintKey,
              child: WebViewWidget(controller: controller),
            ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5B935)),
            ),
        ],
      ),
    );
  }
}
