import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/publicacao.dart';
import '../../theme/soloforte_theme.dart';

// ════════════════════════════════════════════════════════════════════
// PREVIEW CONTEXTUAL DE PUBLICAÇÃO (ADR-007 — iOS Maps Style)
//
// O que este widget É:
//   - DraggableScrollableSheet contextual (~30% peek)
//   - Exibição somente-leitura de dados da Publicacao
//   - CTA explícito para edição via context.go()
//
// O que este widget NÃO É:
//   ❌ Não é rota
//   ❌ Não é fullscreen
//   ❌ Não é editor
//   ❌ Não salva dados
//   ❌ Não navega implicitamente
//   ❌ Não tem AppBar
//   ❌ Não tem abas
// ════════════════════════════════════════════════════════════════════

/// Abre o preview contextual da publicação como bottom sheet.
/// Mapa permanece visível atrás.
/// Navegação para edição ocorre SOMENTE via CTA explícito.
void showPublicacaoPreview(BuildContext context, Publicacao publicacao) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
            color: SoloForteColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(SoloRadius.lg),
              topRight: Radius.circular(SoloRadius.lg),
            ),
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
                    color: SoloForteColors.grayLight,
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
        color: SoloForteColors.grayLight,
        borderRadius: BorderRadius.circular(SoloRadius.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoloRadius.md),
        child: hasCover
            ? Image.network(
                cover.path,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: SoloForteColors.textTertiary,
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
                fontSize: SoloFontSizes.xs,
                fontWeight: SoloFontWeights.semibold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Título
          Text(
            publicacao.title ?? 'Publicação sem título',
            style: SoloTextStyles.headingMedium,
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
              style: SoloTextStyles.body.copyWith(
                color: SoloForteColors.textSecondary,
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
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: SoloForteColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    publicacao.clientName!,
                    style: SoloTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Área
              if (publicacao.areaName != null) ...[
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: SoloForteColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    publicacao.areaName!,
                    style: SoloTextStyles.label,
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
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: SoloForteColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(publicacao.createdAt),
                style: SoloTextStyles.label,
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.photo_library_outlined,
                size: 14,
                color: SoloForteColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${publicacao.media.length} ${publicacao.media.length == 1 ? 'foto' : 'fotos'}',
                style: SoloTextStyles.label,
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
            // Navegar via CTA explícito para rota existente sob /map
            context.go('/map/publicacao/edit?id=${publicacao.id}');
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Ver detalhes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SoloForteColors.greenIOS,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SoloRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: SoloFontSizes.sm,
              fontWeight: SoloFontWeights.semibold,
            ),
          ),
        ),
      ),
    );
  }
}
