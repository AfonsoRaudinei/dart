import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import '../../../core/domain/publicacao.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

/// Preview simplificado de publicação para mapa público.
///
/// Exibe informações básicas da publicação em um bottom sheet.
/// **SOMENTE VISUALIZAÇÃO** - sem botões de edição/exclusão.
void showPublicPublicationPreview(
  BuildContext context,
  Publicacao publication,
) {
  showSoloForteSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (context) =>
        _PublicPublicationPreviewSheet(publication: publication),
  );
}

class _PublicPublicationPreviewSheet extends StatelessWidget {
  final Publicacao publication;

  const _PublicPublicationPreviewSheet({required this.publication});

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final radius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : context.premiumHairline;
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : null;
    final subtitle = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : context.premiumTextSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        border: isIos
            ? const Border(
                top: BorderSide(color: SoloForteSheetSkinIos.sheetBorder),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: isIos ? SoloForteSheetSkinIos.handleSize.width : 40,
            height: isIos ? SoloForteSheetSkinIos.handleSize.height : 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Conteúdo
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem de capa
                  if (publication.media.isNotEmpty)
                    _buildCoverImage(context, isIos, subtitle),

                  const SizedBox(height: 20.0),

                  // Badge de tipo
                  _buildTypeBadge(context, isIos),

                  const SizedBox(height: 12.0),

                  // Título
                  Text(
                    publication.title ?? 'Sem título',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Informações do cliente/área
                  if (publication.clientName != null ||
                      publication.areaName != null)
                    _buildClientInfo(context, subtitle),

                  const SizedBox(height: 16.0),

                  // Descrição
                  if (publication.description != null)
                    Text(
                      publication.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitle,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 20.0),

                  // Data de publicação
                  _buildPublicationDate(context, subtitle),

                  const SizedBox(height: 20.0),

                  // Galeria de imagens (se houver mais de uma)
                  if (publication.media.length > 1)
                    _buildGallery(context, isIos, titleColor, subtitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(
    BuildContext context,
    bool isIos,
    Color subtitle,
  ) {
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : context.premiumSurface;
    final progress = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : PremiumTokens.brandGreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        isIos ? SoloForteSheetSkinIos.cardRadius : 16,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: publication.coverMedia.path,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            return Container(
              color: surface,
              child: Icon(
                Icons.image,
                size: 64,
                color: subtitle,
              ),
            );
          },
          placeholder: (context, url) {
            return Container(
              color: surface,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(progress),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, bool isIos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(
        color: isIos
            ? SoloForteSheetSkinIos.badgeBackground
            : _getTypeColor(publication.type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.badgeBorder)
            : null,
      ),
      child: Text(
        _getTypeLabel(publication.type),
        style: TextStyle(
          fontSize: 12,
          color: isIos
              ? SoloForteSheetSkinIos.badgeText
              : _getTypeColor(publication.type),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context, Color subtitle) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: subtitle),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            [
              if (publication.clientName != null) publication.clientName,
              if (publication.areaName != null) publication.areaName,
            ].join(' • '),
            style: TextStyle(color: subtitle, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicationDate(BuildContext context, Color subtitle) {
    final formatter = DateFormat('dd/MM/yyyy • HH:mm');
    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: subtitle),
        const SizedBox(width: 4),
        Text(
          'Publicado em ${formatter.format(publication.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: subtitle,
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(
    BuildContext context,
    bool isIos,
    Color? titleColor,
    Color subtitle,
  ) {
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : context.premiumSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeria (${publication.media.length} fotos)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: publication.media.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final media = publication.media[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(
                  isIos ? SoloForteSheetSkinIos.cardRadius : 12,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: media.path,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return Container(
                        color: surface,
                        child: Icon(
                          Icons.image,
                          color: subtitle,
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
        return PremiumTokens.brandGreen;
      case PublicacaoType.tecnico:
        return const Color(0xFF9C27B0);
      case PublicacaoType.resultado:
        return PremiumTokens.brandGreen;
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
