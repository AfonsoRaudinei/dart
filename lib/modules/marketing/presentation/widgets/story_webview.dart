import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView que renderiza o HTML já injetado da story.
class StoryWebView extends StatefulWidget {
  final String htmlContent;

  const StoryWebView({required this.htmlContent, super.key});

  @override
  State<StoryWebView> createState() => _StoryWebViewState();
}

class _StoryWebViewState extends State<StoryWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(const Color(0xFF0E1117))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  void didUpdateWidget(covariant StoryWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      setState(() => _loading = true);
      _controller.loadHtmlString(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E1117),
      child: Stack(
        fit: StackFit.expand,
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
}
