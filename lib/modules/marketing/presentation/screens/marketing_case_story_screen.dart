import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/marketing_case.dart';
import '../widgets/story_share_button.dart';
import '../widgets/story_webview.dart';

/// Tela fullscreen da story de um [MarketingCase].
///
/// Retorno ao mapa: SmartButton global (sem FAB local / sem AppBar).
class MarketingCaseStoryScreen extends ConsumerStatefulWidget {
  final MarketingCase marketingCase;

  const MarketingCaseStoryScreen({required this.marketingCase, super.key});

  @override
  ConsumerState<MarketingCaseStoryScreen> createState() =>
      _MarketingCaseStoryScreenState();
}

class _MarketingCaseStoryScreenState
    extends ConsumerState<MarketingCaseStoryScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          StoryWebView(
            marketingCase: widget.marketingCase,
            repaintKey: _repaintKey,
          ),
          Positioned(
            top: top + 12,
            right: 16,
            child: StoryShareButton(
              repaintKey: _repaintKey,
              caseId: widget.marketingCase.id,
            ),
          ),
        ],
      ),
    );
  }
}
