import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/marketing_photo_service.dart';
import '../../domain/marketing_resultado_fotos.dart';

/// Seletor de 1–5 fotos do case Resultado (ADR-065).
///
/// O estado vive no sheet pai: recebe [urls] e devolve a nova lista em
/// [onChanged]. O upload é uma foto por vez; [uploadFoto] permite injetar o
/// serviço em testes (padrão: [MarketingPhotoService], pasta `resultado`).
class FotosResultadoPickerWidget extends StatefulWidget {
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final Future<String?> Function(BuildContext context)? uploadFoto;
  final double height;

  const FotosResultadoPickerWidget({
    super.key,
    required this.urls,
    required this.onChanged,
    this.uploadFoto,
    this.height = 120,
  });

  @override
  State<FotosResultadoPickerWidget> createState() =>
      _FotosResultadoPickerWidgetState();
}

class _FotosResultadoPickerWidgetState
    extends State<FotosResultadoPickerWidget> {
  bool _loading = false;

  bool get _podeAdicionar => widget.urls.length < kMarketingResultadoFotosMax;

  Future<String?> _upload() {
    final injected = widget.uploadFoto;
    if (injected != null) return injected(context);
    return MarketingPhotoService(
      Supabase.instance.client,
    ).pickAndUpload(context: context, folder: 'resultado');
  }

  Future<void> _add() async {
    if (_loading || !_podeAdicionar) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    setState(() => _loading = true);

    try {
      final url = await _upload();
      if (!mounted) return;
      setState(() => _loading = false);
      final limpa = url?.trim() ?? '';
      if (limpa.isEmpty || !_podeAdicionar) return;
      HapticFeedback.mediumImpact();
      widget.onChanged([...widget.urls, limpa]);
    } catch (e, st) {
      AppLogger.error(
        'FotosResultadoPickerWidget upload error',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar a foto. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _remove(int index) {
    HapticFeedback.selectionClick();
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover foto?'),
        content: const Text('A foto será removida do case.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      if (index >= widget.urls.length) return;
      widget.onChanged([...widget.urls]..removeAt(index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final urls = widget.urls;
    final mostrarTile = _podeAdicionar || _loading;
    final itemCount = urls.length + (mostrarTile ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                i < urls.length ? _miniatura(urls[i], i, v) : _tileAdicionar(v),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${urls.length}/$kMarketingResultadoFotosMax',
            key: const ValueKey('fotos-resultado-contador'),
            style: TextStyle(fontSize: 12, color: v.subtitleColor),
          ),
        ),
      ],
    );
  }

  Widget _miniatura(String url, int index, SoloForteSheetVisuals v) {
    final size = widget.height;
    return SizedBox(
      key: ValueKey('fotos-resultado-miniatura-$index'),
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(v.cardRadius),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => ColoredBox(
                color: v.cardBackground,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 32,
                  color: v.subtitleColor,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              key: ValueKey('fotos-resultado-remover-$index'),
              onTap: () => _remove(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                // Branco sobre a foto: contraste intencional com a imagem.
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileAdicionar(SoloForteSheetVisuals v) {
    final vazio = widget.urls.isEmpty;
    final erro = Colors.red.shade400;
    final corTexto = vazio ? erro : v.titleColor;

    return GestureDetector(
      key: const ValueKey('fotos-resultado-adicionar'),
      onTap: _loading ? null : _add,
      child: Container(
        width: widget.height,
        height: widget.height,
        decoration: BoxDecoration(
          color: v.cardBackground,
          borderRadius: BorderRadius.circular(v.cardRadius),
          border: Border.all(
            color: vazio ? Colors.red.shade300 : v.cardBorder,
            width: vazio ? 1.5 : 1,
          ),
          boxShadow: v.cardShadows,
        ),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: v.isIos ? v.iconStroke : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enviando foto...',
                      style: TextStyle(fontSize: 12, color: v.subtitleColor),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vazio
                        ? Icons.photo_camera_outlined
                        : Icons.add_a_photo_outlined,
                    size: 24,
                    color: vazio ? erro : v.subtitleColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adicionar foto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                  if (vazio) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Obrigatória',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: erro,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
