import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../domain/entities/marketing_case.dart';
import '../widgets/story_html_injector.dart';
import '../widgets/story_share_button.dart';
import '../widgets/story_webview.dart';

/// Tela fullscreen da story de um [MarketingCase].
///
/// Retorno ao mapa: SmartButton global (sem FAB local / sem AppBar).
///
/// Opção B: injeta o HTML uma vez e passa o resultado para WebView + Share.
class MarketingCaseStoryScreen extends ConsumerStatefulWidget {
  final MarketingCase marketingCase;

  const MarketingCaseStoryScreen({required this.marketingCase, super.key});

  @override
  ConsumerState<MarketingCaseStoryScreen> createState() =>
      _MarketingCaseStoryScreenState();
}

class _MarketingCaseStoryScreenState
    extends ConsumerState<MarketingCaseStoryScreen> {
  late final Future<String> _htmlFuture;

  @override
  void initState() {
    super.initState();
    _htmlFuture = _buildInjectedHtml(widget.marketingCase);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<String>(
        future: _htmlFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar a story.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5B935)),
            );
          }

          final html = snapshot.data!;
          return Stack(
            fit: StackFit.expand,
            children: [
              StoryWebView(htmlContent: html),
              Positioned(
                top: top + 12,
                right: 16,
                child: StoryShareButton(
                  htmlContent: html,
                  caseId: widget.marketingCase.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<String> _buildInjectedHtml(MarketingCase marketingCase) async {
  final template = await rootBundle.loadString('assets/story.html');
  final logoSrc = await RelatorioHtmlRenderer.assetImageToBase64(
    RelatorioHtmlRenderer.soloForteLogoAsset,
  );

  final fotoPrincipal = await _fotoParaSrc(marketingCase.fotoPrincipalUrl);
  final fotoAntes = await _fotoParaSrc(marketingCase.fotoAntesUrl);
  final fotoDepois = await _fotoParaSrc(marketingCase.fotoDepoisUrl);

  return injectStoryData(
    template,
    marketingCase,
    fotoSrc: fotoPrincipal,
    fotoAntesSrc: fotoAntes,
    fotoDepoisSrc: fotoDepois,
    logoSrc: logoSrc,
  );
}

Future<String?> _fotoParaSrc(String? url) async {
  if (url == null || url.trim().isEmpty) return null;
  final resolved = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(url);
  return resolved.isEmpty ? null : resolved;
}
