import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';
import '../providers/publicacao_providers.dart';

/// Tela de Detalhe da Publicação Técnica — PASSO 4
///
/// Rota: [AppRoutes.publicacaoDetail] (/consultoria/publicacoes/:id)
///
/// Somente leitura — sem edição.
/// Navegação: sem AppBar. SmartButton global cuida do retorno.
class PublicacaoDetailScreen extends ConsumerWidget {
  const PublicacaoDetailScreen({super.key, required this.publicacaoId});

  final String publicacaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicacaoDetailProvider(id: publicacaoId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar publicação:\n$error',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (publicacao) {
            if (publicacao == null) {
              return const Center(
                child: Text(
                  'Publicação não encontrada.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                _buildContent(context, publicacao),
                if (publicacao.fazendaRef != null ||
                    publicacao.talhaoRef != null)
                  _buildReferenceCard(publicacao),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PublicacaoTecnica publicacao) {
    final formatter = DateFormat('dd/MM/yyyy');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha superior: Badge + Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TemaBadge(tema: publicacao.tema),
                Text(
                  formatter.format(publicacao.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              publicacao.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            // Safra (se houver)
            if (publicacao.safra != null) ...[
              const SizedBox(height: 8),
              Text(
                'Safra ${publicacao.safra}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],

            const SizedBox(height: 20),

            // Card de conteúdo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                publicacao.conteudo,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceCard(PublicacaoTecnica publicacao) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          border: Border.all(color: const Color(0xFFBAE6FD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Color(0xFF0369A1), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Referência de campo vinculada',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0369A1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════

class _TemaBadge extends StatelessWidget {
  const _TemaBadge({required this.tema});

  final PublicacaoTema tema;

  @override
  Widget build(BuildContext context) {
    final color = _getTemaColor(tema);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getTemaLabel(tema),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTemaColor(PublicacaoTema tema) {
    switch (tema) {
      case PublicacaoTema.praga:
        return const Color(0xFFDC2626);
      case PublicacaoTema.doenca:
        return const Color(0xFF7C3AED);
      case PublicacaoTema.solo:
        return const Color(0xFF92400E);
      case PublicacaoTema.fenologia:
        return const Color(0xFF059669);
      case PublicacaoTema.recomendacao:
        return const Color(0xFF1A56DB);
      case PublicacaoTema.outro:
        return const Color(0xFF6B7280);
    }
  }

  String _getTemaLabel(PublicacaoTema tema) {
    switch (tema) {
      case PublicacaoTema.praga:
        return 'Praga';
      case PublicacaoTema.doenca:
        return 'Doença';
      case PublicacaoTema.solo:
        return 'Solo';
      case PublicacaoTema.fenologia:
        return 'Fenologia';
      case PublicacaoTema.recomendacao:
        return 'Recomendação';
      case PublicacaoTema.outro:
        return 'Outro';
    }
  }
}
