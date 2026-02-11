import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/domain/publicacao.dart';
import '../../theme/soloforte_theme.dart';

/// Gerador de pins para publicações no mapa público.
///
/// Exibe publicações como markers clusterizados.
/// **SOMENTE VISUALIZAÇÃO** - sem ações de edição/exclusão.
class PublicPublicationPins {
  /// Cria lista de markers para publicações públicas com animação fade in
  static List<Marker> createMarkers(
    List<Publicacao> publications,
    Function(Publicacao) onTap,
  ) {
    return publications.map((pub) {
      return Marker(
        key: ValueKey('pub_${pub.id}'),
        point: pub.location,
        width: 60,
        height: 60,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () => onTap(pub),
            child: _PublicationPin(publication: pub),
          ),
        ),
      );
    }).toList();
  }
}

/// Widget individual do pin de publicação
class _PublicationPin extends StatelessWidget {
  final Publicacao publication;

  const _PublicationPin({required this.publication});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Shadow
        Positioned(
          bottom: 0,
          left: 10,
          right: 10,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Pin principal
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: SoloForteColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _getTypeColor(publication.type),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: publication.media.isNotEmpty
                ? Image.network(
                    publication.coverMedia.path,
                    fit: BoxFit.cover,
                    // Cache de imagens
                    cacheWidth: 100,
                    cacheHeight: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),
        ),

        // Badge de tipo (opcional)
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getTypeColor(publication.type),
              shape: BoxShape.circle,
              border: Border.all(color: SoloForteColors.white, width: 2),
            ),
            child: Icon(
              _getTypeIcon(publication.type),
              size: 10,
              color: SoloForteColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: SoloForteColors.grayLight,
      child: Icon(Icons.image, color: SoloForteColors.textSecondary, size: 24),
    );
  }

  Color _getTypeColor(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return SoloForteColors.brand;
      case PublicacaoType.tecnico:
        return const Color(0xFF9C27B0); // Roxo
      case PublicacaoType.resultado:
        return SoloForteColors.greenIOS;
      case PublicacaoType.comparativo:
        return const Color(0xFFFF9800); // Laranja
      case PublicacaoType.caseSucesso:
        return const Color(0xFF2196F3); // Azul
    }
  }

  IconData _getTypeIcon(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return Icons.business;
      case PublicacaoType.tecnico:
        return Icons.science;
      case PublicacaoType.resultado:
        return Icons.trending_up;
      case PublicacaoType.comparativo:
        return Icons.compare;
      case PublicacaoType.caseSucesso:
        return Icons.star;
    }
  }
}
