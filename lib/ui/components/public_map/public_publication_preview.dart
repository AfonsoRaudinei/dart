import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/publicacao.dart';
import '../../theme/soloforte_theme.dart';

/// Preview simplificado de publicação para mapa público.
///
/// Exibe informações básicas da publicação em um bottom sheet.
/// **SOMENTE VISUALIZAÇÃO** - sem botões de edição/exclusão.
void showPublicPublicationPreview(
  BuildContext context,
  Publicacao publication,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _PublicPublicationPreviewSheet(publication: publication),
  );
}

class _PublicPublicationPreviewSheet extends StatelessWidget {
  final Publicacao publication;

  const _PublicPublicationPreviewSheet({required this.publication});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: SoloForteColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SoloForteColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Conteúdo
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SoloSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem de capa
                  if (publication.media.isNotEmpty) _buildCoverImage(context),

                  const SizedBox(height: SoloSpacing.lg),

                  // Badge de tipo
                  _buildTypeBadge(),

                  const SizedBox(height: SoloSpacing.sm),

                  // Título
                  Text(
                    publication.title ?? 'Sem título',
                    style: SoloTextStyles.headingLarge.copyWith(fontSize: 24),
                  ),

                  const SizedBox(height: SoloSpacing.sm),

                  // Informações do cliente/área
                  if (publication.clientName != null ||
                      publication.areaName != null)
                    _buildClientInfo(),

                  const SizedBox(height: SoloSpacing.md),

                  // Descrição
                  if (publication.description != null)
                    Text(
                      publication.description!,
                      style: SoloTextStyles.body.copyWith(
                        color: SoloForteColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: SoloSpacing.lg),

                  // Data de publicação
                  _buildPublicationDate(),

                  const SizedBox(height: SoloSpacing.lg),

                  // Galeria de imagens (se houver mais de uma)
                  if (publication.media.length > 1) _buildGallery(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    return ClipRRect(
      borderRadius: SoloRadius.radiusLg,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          publication.coverMedia.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: SoloForteColors.grayLight,
              child: const Icon(
                Icons.image,
                size: 64,
                color: SoloForteColors.textSecondary,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: SoloForteColors.grayLight,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SoloForteColors.greenIOS,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SoloSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getTypeColor(publication.type).withValues(alpha: 0.1),
        borderRadius: SoloRadius.radiusSm,
      ),
      child: Text(
        _getTypeLabel(publication.type),
        style: SoloTextStyles.label.copyWith(
          color: _getTypeColor(publication.type),
          fontWeight: SoloFontWeights.semibold,
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          size: 16,
          color: SoloForteColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            [
              if (publication.clientName != null) publication.clientName,
              if (publication.areaName != null) publication.areaName,
            ].join(' • '),
            style: SoloTextStyles.body.copyWith(
              color: SoloForteColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicationDate() {
    final formatter = DateFormat('dd/MM/yyyy • HH:mm');
    return Row(
      children: [
        const Icon(
          Icons.schedule,
          size: 16,
          color: SoloForteColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          'Publicado em ${formatter.format(publication.createdAt)}',
          style: SoloTextStyles.label.copyWith(
            color: SoloForteColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeria (${publication.media.length} fotos)',
          style: SoloTextStyles.headingMedium,
        ),
        const SizedBox(height: SoloSpacing.sm),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: publication.media.length,
            separatorBuilder: (_, __) => const SizedBox(width: SoloSpacing.sm),
            itemBuilder: (context, index) {
              final media = publication.media[index];
              return ClipRRect(
                borderRadius: SoloRadius.radiusMd,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    media.path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: SoloForteColors.grayLight,
                        child: const Icon(
                          Icons.image,
                          color: SoloForteColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return SoloForteColors.brand;
      case PublicacaoType.tecnico:
        return const Color(0xFF9C27B0);
      case PublicacaoType.resultado:
        return SoloForteColors.greenIOS;
      case PublicacaoType.comparativo:
        return const Color(0xFFFF9800);
      case PublicacaoType.caseSucesso:
        return const Color(0xFF2196F3);
    }
  }

  String _getTypeLabel(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return 'INSTITUCIONAL';
      case PublicacaoType.tecnico:
        return 'TÉCNICO';
      case PublicacaoType.resultado:
        return 'RESULTADO';
      case PublicacaoType.comparativo:
        return 'COMPARATIVO';
      case PublicacaoType.caseSucesso:
        return 'CASE DE SUCESSO';
    }
  }
}
