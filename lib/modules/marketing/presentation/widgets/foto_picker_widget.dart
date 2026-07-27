import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_media_ref.dart';

import '../../data/services/marketing_photo_service.dart';
import 'marketing_media_image.dart';

/// Widget reutilizável de seleção e preview de foto para Marketing Cases.
///
/// Offline-first: persiste localmente e tenta upload; se sem rede, mantém
/// path local no case (`pending_sync`) até o sync.
///
/// Parâmetros:
///   [label]       Texto do placeholder (ex: 'Foto Principal')
///   [url]         URL remota ou path local (null = sem foto)
///   [onChanged]   Callback com a nova ref (null = foto removida)
///   [folder]      Subpasta no bucket (ex: 'resultado', 'avaliacoes')
///   [height]      Altura do bloco de foto
///   [required]    Se true, destaca em vermelho quando sem foto
class FotoPickerWidget extends StatefulWidget {
  final String label;
  final String? url;
  final void Function(String? url) onChanged;
  final String? folder;
  final double height;
  final bool required;

  const FotoPickerWidget({
    super.key,
    required this.label,
    required this.url,
    required this.onChanged,
    this.folder,
    this.height = 160,
    this.required = false,
  });

  @override
  State<FotoPickerWidget> createState() => _FotoPickerWidgetState();
}

class _FotoPickerWidgetState extends State<FotoPickerWidget> {
  static const Color _bgDark = Color(0xFF2C2C2E);
  static const Color _borderDark = Color(0xFF3A3A3C);
  bool _loading = false;

  Future<void> _pick() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);

    try {
      final service = MarketingPhotoService(Supabase.instance.client);
      final ref = await service.pickAndResolve(
        context: context,
        folder: widget.folder,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (ref != null) {
        HapticFeedback.mediumImpact();
        widget.onChanged(ref);
        if (MarketingMediaRef.isLocalPath(ref) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sem conexão — foto salva localmente e será enviada na sincronização.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, st) {
      AppLogger.error('FotoPickerWidget pick error', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a foto. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _remove() {
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
      if (confirmed == true) widget.onChanged(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.url != null && widget.url!.isNotEmpty;
    final isEmpty = !hasPhoto && widget.required;

    return GestureDetector(
      onTap: hasPhoto ? null : _pick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEmpty
                ? Colors.red.shade300
                : hasPhoto
                ? Colors.transparent
                : _borderDark,
            width: isEmpty ? 1.5 : 1,
          ),
          color: hasPhoto ? null : _bgDark,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: _loading
              ? _buildLoading()
              : hasPhoto
              ? _buildPreview(widget.url!)
              : _buildPlaceholder(isEmpty),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 8),
          Text(
            'Salvando foto...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MarketingMediaImage(
          source: url,
          fit: BoxFit.cover,
          placeholder: (_) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _remove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 12,
          right: 48,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Trocar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isError) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 28,
          color: isError ? Colors.red.shade400 : Colors.white38,
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isError ? Colors.red.shade400 : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Toque para selecionar',
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),
        if (isError) ...[
          const SizedBox(height: 4),
          Text(
            'Obrigatória',
            style: TextStyle(
              fontSize: 11,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
