import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../design/sf_icons.dart';
import '../utils/share_position.dart';
import 'report_export_service.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// Ações opcionais na AppBar do viewer (Relatórios — opt-in).
///
/// Agenda e outros módulos omitam [actions] para manter só exportação.
class HtmlReportViewerActions {
  const HtmlReportViewerActions({
    this.onEdit,
    this.onViewLocation,
    this.onPublish,
    this.onConfirm,
    this.onDelete,
    this.publishDialogTitle = 'Publicar?',
    this.publishDialogMessage,
    this.confirmDialogTitle = 'Confirmar?',
    this.confirmDialogMessage,
    this.deleteDialogTitle = 'Excluir?',
    this.deleteDialogMessage = 'Esta ação não pode ser desfeita.',
  });

  final Future<void> Function(BuildContext viewerContext)? onEdit;
  final Future<void> Function(BuildContext viewerContext)? onViewLocation;

  /// Retorna `true` quando concluído — viewer fecha após sucesso.
  final Future<bool> Function(BuildContext viewerContext)? onPublish;
  final String publishDialogTitle;
  final String? publishDialogMessage;

  final Future<bool> Function(BuildContext viewerContext)? onConfirm;
  final String confirmDialogTitle;
  final String? confirmDialogMessage;

  final Future<bool> Function(BuildContext viewerContext)? onDelete;
  final String deleteDialogTitle;
  final String deleteDialogMessage;
}

/// Widget genérico para exibir qualquer relatório HTML gerado pelos renderers.
class HtmlReportViewer extends StatefulWidget {
  final String title;
  final String htmlContent;
  final String? fileBaseName;
  final Map<String, dynamic>? jsonData;
  final String? csvData;
  final ReportExportService exportService;
  final HtmlReportViewerActions? actions;

  /// Gerador opcional de PDF secundário (ex.: planejamento semanal).
  final Future<Uint8List> Function()? pdfBytesProvider;

  const HtmlReportViewer({
    super.key,
    required this.title,
    required this.htmlContent,
    this.fileBaseName,
    this.jsonData,
    this.csvData,
    this.exportService = const ReportExportService(),
    this.pdfBytesProvider,
    this.actions,
  });

  @override
  State<HtmlReportViewer> createState() => _HtmlReportViewerState();
}

bool _htmlReportViewerUseTestBody() {
  if (kIsWeb) return false;
  return Platform.environment.containsKey('FLUTTER_TEST');
}

class _HtmlReportViewerState extends State<HtmlReportViewer> {
  WebViewController? _controller;
  bool _loading = true;
  bool _actionBusy = false;
  final GlobalKey _exportButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_htmlReportViewerUseTestBody()) {
      _loading = false;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _runBoolAction(
    Future<bool> Function(BuildContext viewerContext) action, {
    required String confirmTitle,
    String? confirmMessage,
    required String confirmActionLabel,
    bool destructive = false,
  }) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      if (confirmMessage != null) {
        final confirmed = await _confirmAction(
          title: confirmTitle,
          message: confirmMessage,
          actionLabel: confirmActionLabel,
          destructive: destructive,
        );
        if (confirmed != true || !mounted) return;
      }
      final done = await action(context);
      if (!mounted) return;
      if (done) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _runVoidAction(
    Future<void> Function(BuildContext viewerContext) action,
  ) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await action(context);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  List<Widget> _buildActionIcons() {
    final actions = widget.actions;
    if (actions == null) return const [];

    final icons = <Widget>[];

    if (actions.onEdit != null) {
      icons.add(
        IconButton(
          tooltip: 'Editar',
          onPressed: _actionBusy ? null : () => _runVoidAction(actions.onEdit!),
          icon: const Icon(Icons.edit_outlined),
        ),
      );
    }

    if (actions.onViewLocation != null) {
      icons.add(
        IconButton(
          tooltip: 'Ver localização',
          onPressed: _actionBusy
              ? null
              : () => _runVoidAction(actions.onViewLocation!),
          icon: const Icon(SFIcons.pinFill),
        ),
      );
    }

    if (actions.onPublish != null) {
      icons.add(
        IconButton(
          tooltip: 'Publicar',
          onPressed: _actionBusy
              ? null
              : () => _runBoolAction(
                  actions.onPublish!,
                  confirmTitle: actions.publishDialogTitle,
                  confirmMessage: actions.publishDialogMessage ??
                      'Confirma a publicação deste item?',
                  confirmActionLabel: 'Publicar',
                ),
          icon: const Icon(Icons.publish_outlined),
        ),
      );
    }

    if (actions.onConfirm != null) {
      icons.add(
        IconButton(
          tooltip: 'Confirmar',
          onPressed: _actionBusy
              ? null
              : () => _runBoolAction(
                  actions.onConfirm!,
                  confirmTitle: actions.confirmDialogTitle,
                  confirmMessage: actions.confirmDialogMessage ??
                      'Marcar como confirmada?',
                  confirmActionLabel: 'Confirmar',
                ),
          icon: const Icon(Icons.check_circle_outline),
        ),
      );
    }

    if (actions.onDelete != null) {
      icons.add(
        IconButton(
          tooltip: 'Excluir',
          onPressed: _actionBusy
              ? null
              : () => _runBoolAction(
                  actions.onDelete!,
                  confirmTitle: actions.deleteDialogTitle,
                  confirmMessage: actions.deleteDialogMessage,
                  confirmActionLabel: 'Excluir',
                  destructive: true,
                ),
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFFCDD2)),
        ),
      );
    }

    return icons;
  }

  @override
  Widget build(BuildContext context) {
    final actionIcons = _buildActionIcons();

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
          if (_actionBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ...actionIcons,
          if (widget.pdfBytesProvider != null)
            PopupMenuButton<String>(
              key: _exportButtonKey,
              tooltip: 'Exportar',
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (value) {
                if (value == 'html') {
                  _exportHtml();
                } else if (value == 'pdf') {
                  _exportPdf();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'html',
                  child: Text('Compartilhar HTML'),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Text('Compartilhar PDF'),
                ),
              ],
            )
          else
            IconButton(
              key: _exportButtonKey,
              tooltip: 'Exportar',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: _actionBusy ? null : _exportHtml,
            ),
        ],
      ),
      body: _htmlReportViewerUseTestBody()
          ? const Center(
              child: Text(
                'Pré-visualização HTML',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
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
        ).showSnackBar(
          SnackBar(content: Text(userFacingError(e, action: 'Erro ao exportar'))),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    final provider = widget.pdfBytesProvider;
    if (provider == null) return;
    try {
      final bytes = await provider();
      final dir = await getTemporaryDirectory();
      final base =
          widget.fileBaseName?.trim().isNotEmpty == true
          ? widget.fileBaseName!.trim()
          : 'soloforte_relatorio';
      final file = File('${dir.path}/$base.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: widget.title,
        sharePositionOrigin: resolveSharePositionOrigin(
          context,
          anchorKey: _exportButtonKey,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(userFacingError(e, action: 'Erro ao gerar PDF'))),
        );
      }
    }
  }
}
