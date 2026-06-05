import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../../../core/design/sf_icons.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import '../../../core/domain/publicacao.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// PREVIEW INDIVIDUAL DE PIN DE PUBLICAÇÃO (iOS Maps Style)
// ════════════════════════════════════════════════════════════════════
//
// QUANDO USAR:
//   ✅ Usuário toca em PIN de publicação no mapa
//   ✅ Preview contextual rápido (30% peek com scroll)
//   ✅ CTA para navegação completa/edição
//
// NÃO CONFUNDIR COM:
//   ⚠️ PublicacoesSheet → Lista completa no MapBottomSheet
//   ⚠️ Usado via botão de publicações na toolbar
//
// ARQUITETURA:
//   - ADR-007 compliant (DraggableScrollableSheet)
//   - Exibição somente-leitura
//   - Navegação explícita via context.go()
//   - Não é rota, não é fullscreen, não é editor
//
// ════════════════════════════════════════════════════════════════════

/// Abre o preview contextual da publicação como bottom sheet.
/// Mapa permanece visível atrás.
/// Navegação para edição ocorre SOMENTE via CTA explícito.
void showPublicacaoPreview(BuildContext context, Publicacao publicacao) {
  HapticFeedback.lightImpact();
  showSoloForteSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    // Mapa fica visível atrás — sem barreira opaca
    barrierColor: Colors.black.withValues(alpha: 0.15),
    builder: (_) => _PublicacaoPreviewSheet(publicacao: publicacao),
  );
}

class _PublicacaoPreviewSheet extends StatelessWidget {
  final Publicacao publicacao;

  const _PublicacaoPreviewSheet({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32, // Peek ~30% (iOS Maps style)
      minChildSize: 0.20,
      maxChildSize: 0.70,
      snap: true,
      snapSizes: const [0.32, 0.55, 0.70],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: SoloForteSheetTokens.sheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PremiumTokens.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Imagem de capa ──
              _CoverSection(publicacao: publicacao),

              // ── Cabeçalho ──
              _HeaderSection(publicacao: publicacao),

              // ── Informações ──
              _InfoSection(publicacao: publicacao),

              // ── CTA (ÚNICA navegação permitida) ──
              _CTASection(publicacao: publicacao),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// Seção de imagem de capa.
class _CoverSection extends StatelessWidget {
  final Publicacao publicacao;
  const _CoverSection({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    final cover = publicacao.coverMedia;
    final hasCover = cover.path.isNotEmpty;

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PremiumTokens.surfaceLight,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: hasCover
            ? CachedNetworkImage(
                imageUrl: cover.path,
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        SFIcons.image,
        size: 48,
        color: PremiumTokens.textTertiaryLight,
      ),
    );
  }
}

/// Seção de cabeçalho: tipo + título.
class _HeaderSection extends StatelessWidget {
  final Publicacao publicacao;
  const _HeaderSection({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getTypeLabel(),
              style: TextStyle(
                color: _getTypeColor(),
                fontSize: 10.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Título
          Text(
            publicacao.title ?? 'Publicação sem título',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (publicacao.type) {
      case PublicacaoType.institucional:
        return const Color(0xFF2196F3);
      case PublicacaoType.tecnico:
        return const Color(0xFF4CAF50);
      case PublicacaoType.resultado:
        return const Color(0xFFFF9800);
      case PublicacaoType.comparativo:
        return const Color(0xFF9C27B0);
      case PublicacaoType.caseSucesso:
        return const Color(0xFFFFC107);
    }
  }

  String _getTypeLabel() {
    switch (publicacao.type) {
      case PublicacaoType.institucional:
        return 'Institucional';
      case PublicacaoType.tecnico:
        return 'Técnico';
      case PublicacaoType.resultado:
        return 'Resultado';
      case PublicacaoType.comparativo:
        return 'Comparativo';
      case PublicacaoType.caseSucesso:
        return 'Case de Sucesso';
    }
  }
}

/// Seção de informações contextuais.
class _InfoSection extends StatelessWidget {
  final Publicacao publicacao;
  const _InfoSection({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descrição
          if (publicacao.description != null &&
              publicacao.description!.isNotEmpty) ...[
            Text(
              publicacao.description!,
              style: const TextStyle(fontSize: 14).copyWith(
                color: PremiumTokens.textSecondaryLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Metadados em linha
          Row(
            children: [
              // Cliente
              if (publicacao.clientName != null) ...[
                const Icon(
                  SFIcons.personOutline,
                  size: 14,
                  color: PremiumTokens.textTertiaryLight,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    publicacao.clientName!,
                    style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Área
              if (publicacao.areaName != null) ...[
                const Icon(
                  SFIcons.place,
                  size: 14,
                  color: PremiumTokens.textTertiaryLight,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    publicacao.areaName!,
                    style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Data + Mídias
          Row(
            children: [
              const Icon(
                SFIcons.calendar,
                size: 14,
                color: PremiumTokens.textTertiaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(publicacao.createdAt),
                style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight),
              ),
              const SizedBox(width: 16),
              const Icon(
                SFIcons.photoLibrary,
                size: 14,
                color: PremiumTokens.textTertiaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${publicacao.media.length} ${publicacao.media.length == 1 ? 'foto' : 'fotos'}',
                style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seção de CTA — ÚNICA via de navegação para edição.
/// Usa context.go() com rota existente sob /map (L0).
class _CTASection extends StatelessWidget {
  final Publicacao publicacao;
  const _CTASection({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // ⚠️ pop() local do sheet — encerra APENAS o preview (estado local).
            // NÃO é navegação entre rotas. Permitido por ADR-007.
            Navigator.of(context).pop();
            // Navegar via CTA explícito para rota top-level /publicacoes/edit (ADR-007)
            context.go('/publicacoes/edit?id=${publicacao.id}');
          },
          icon: const Icon(SFIcons.openInNew, size: 18),
          label: const Text('Ver detalhes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PremiumTokens.brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
