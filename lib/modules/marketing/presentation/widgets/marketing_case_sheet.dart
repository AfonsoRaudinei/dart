import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

/// Bottom Sheet de visualização detalhada de um Case de Marketing
/// Aberto ao tocar num pin no mapa (Passo 8)
class MarketingCaseSheet extends StatelessWidget {
  final MarketingCase marketingCase;

  const MarketingCaseSheet({super.key, required this.marketingCase});

  /// Exibe o sheet como modal drag‑to‑dismiss
  static void show(BuildContext context, MarketingCase marketingCase) {
    HapticFeedback.lightImpact();
    showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => MarketingCaseSheet(marketingCase: marketingCase),
    );
  }

  Color get _planoColor {
    switch (marketingCase.visibilidade) {
      case PlanoMarketing.ouro:
        return const Color(0xFFFFB800);
      case PlanoMarketing.prata:
        return const Color(0xFF9EA9B2);
      case PlanoMarketing.bronze:
        return const Color(0xFFA0522D);
    }
  }

  IconData get _planoIcon {
    switch (marketingCase.visibilidade) {
      case PlanoMarketing.ouro:
        return Icons.workspace_premium_rounded;
      case PlanoMarketing.prata:
        return Icons.verified_rounded;
      case PlanoMarketing.bronze:
        return Icons.star_border_rounded;
    }
  }

  String get _tipoLabel {
    switch (marketingCase.tipo) {
      case CaseTipo.resultado:
        return 'Resultado';
      case CaseTipo.antesDepois:
        return 'Antes/Depois';
      case CaseTipo.avaliacao:
        return 'Avaliação';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.7, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: SoloForteSheetTokens.sheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ─────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Conteúdo scrollável ───────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // ── Badge de Plano + Tipo ──────────────────
                    Row(
                      children: [
                        // Plano
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _planoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _planoColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_planoIcon, color: _planoColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                marketingCase.visibilidade.name.toUpperCase(),
                                style: TextStyle(
                                  color: _planoColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tipo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PremiumTokens.brandGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _tipoLabel,
                            style: const TextStyle(
                              color: PremiumTokens.brandGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Produto ────────────────────────────────
                    Text(
                      marketingCase.produtoUtilizado,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: PremiumTokens.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            marketingCase.localizacaoTexto,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: PremiumTokens.textSecondaryLight,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Foto principal ─────────────────────────
                    if (marketingCase.fotoPrincipalUrl != null)
                      _buildFoto(marketingCase.fotoPrincipalUrl!),

                    // ── Métricas destaque ──────────────────────
                    _buildMetricasRow(context),
                    const SizedBox(height: 20),

                    // ── Produtor / Fazenda ─────────────────────
                    _buildInfoSection(
                      context,
                      'Produtor / Fazenda',
                      marketingCase.produtorFazenda,
                    ),
                    if (marketingCase.descricao != null) ...[
                      _buildInfoSection(
                        context,
                        'Descrição',
                        marketingCase.descricao!,
                      ),
                    ],

                    // ── Tipo Resultado: específico ─────────────
                    if (marketingCase.tipo == CaseTipo.resultado) ...[
                      if (marketingCase.quantidadeProduzida != null)
                        _buildInfoSection(
                          context,
                          'Quantidade Produzida',
                          '${marketingCase.quantidadeProduzida!.toStringAsFixed(1)} ${marketingCase.produtividadeUnidade?.toValue() ?? ''}',
                        ),
                      if (marketingCase.economiaGerada != null)
                        _buildInfoSection(
                          context,
                          'Economia Gerada',
                          marketingCase.economiaGerada!,
                        ),
                    ],

                    // ── Tipo Antes/Depois ──────────────────────
                    if (marketingCase.tipo == CaseTipo.antesDepois) ...[
                      if (marketingCase.ganhoProdutividade != null)
                        _buildInfoSection(
                          context,
                          'Ganho de Produtividade',
                          marketingCase.ganhoProdutividade!,
                        ),
                      if (marketingCase.economiaGerada != null)
                        _buildInfoSection(
                          context,
                          'Economia Gerada',
                          marketingCase.economiaGerada!,
                        ),
                      if (marketingCase.fotoAntesUrl != null ||
                          marketingCase.fotoDepoisUrl != null)
                        _buildAntesDepoisFotos(context),
                    ],

                    // ── Tipo Avaliação ─────────────────────────
                    if (marketingCase.tipo == CaseTipo.avaliacao) ...[
                      if (marketingCase.nomeTalhao != null) ...[
                        _buildInfoSection(
                          context,
                          'Talhão',
                          '${marketingCase.nomeTalhao!}${marketingCase.tamanhoHa != null ? ' — ${marketingCase.tamanhoHa!.toStringAsFixed(1)} ha' : ''}',
                        ),
                      ],
                      if (marketingCase.avaliacoes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAvaliacoesList(context),
                      ],
                      if (marketingCase.roi != null) ...[
                        const SizedBox(height: 12),
                        _buildRoiCard(context),
                      ],
                      if (marketingCase.conclusao != null) ...[
                        const SizedBox(height: 12),
                        _buildConclusaoCard(context),
                      ],
                    ],

                    // ── Vendedor ───────────────────────────────
                    if (marketingCase.nomeVendedor != null) ...[
                      const SizedBox(height: 20),
                      _buildVendedorCard(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Builders de seção ────────────────────────────────────────

  Widget _buildFoto(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            decoration: const BoxDecoration(color: Color(0xFFE5E5EA)),
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricasRow(BuildContext context) {
    final items = <_MetricaItem>[];

    if (marketingCase.produtividadeValor != null) {
      items.add(
        _MetricaItem(
          label: 'Produtividade',
          value:
              '${marketingCase.produtividadeValor!.toStringAsFixed(1)} ${marketingCase.produtividadeUnidade?.toValue() ?? ''}',
          icon: Icons.bar_chart_rounded,
          color: PremiumTokens.brandGreen,
        ),
      );
    }
    if (marketingCase.roi != null) {
      items.add(
        _MetricaItem(
          label: 'ROI',
          value:
              '${marketingCase.roi!.roiCalculado >= 0 ? '+' : ''}${marketingCase.roi!.roiCalculado.toStringAsFixed(1)}%',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF34C759),
        ),
      );
    }
    if (marketingCase.economiaGerada != null) {
      items.add(
        _MetricaItem(
          label: 'Economia',
          value: marketingCase.economiaGerada!,
          icon: Icons.savings_outlined,
          color: const Color(0xFFFFB800),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: item.color, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: item.color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoSection(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: PremiumTokens.textSecondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntesDepoisFotos(BuildContext context) {
    return Row(
      children: [
        if (marketingCase.fotoAntesUrl != null)
          Expanded(
            child: Column(
              children: [
                _buildFotoMini(marketingCase.fotoAntesUrl!),
                const SizedBox(height: 4),
                const Text(
                  'Antes',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        if (marketingCase.fotoDepoisUrl != null)
          Expanded(
            child: Column(
              children: [
                _buildFotoMini(marketingCase.fotoDepoisUrl!),
                const SizedBox(height: 4),
                const Text(
                  'Depois',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PremiumTokens.brandGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFotoMini(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 130,
          decoration: const BoxDecoration(color: Color(0xFFE5E5EA)),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildAvaliacoesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AVALIAÇÕES (${marketingCase.avaliacoes.length})',
          style: const TextStyle(
            color: PremiumTokens.textSecondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...marketingCase.avaliacoes.map(
          (av) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5EA)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3F5C),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    '${av.ladoA.label} vs ${av.ladoB.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLadoInfo(
                          av.ladoA.label,
                          av.ladoA.tipoCultura,
                          av.ladoA.observacoes,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLadoInfo(
                          av.ladoB.label,
                          av.ladoB.tipoCultura,
                          av.ladoB.observacoes,
                          isB: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLadoInfo(
    String label,
    String? cultura,
    String? obs, {
    bool isB = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isB ? PremiumTokens.brandGreen : null,
          ),
        ),
        if (cultura != null && cultura.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            cultura,
            style: const TextStyle(
              fontSize: 11,
              color: PremiumTokens.textSecondaryLight,
            ),
          ),
        ],
        if (obs != null && obs.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(obs, style: const TextStyle(fontSize: 11, height: 1.3)),
        ],
      ],
    );
  }

  Widget _buildRoiCard(BuildContext context) {
    final roi = marketingCase.roi!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF34C759)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ROI Calculado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${roi.roiCalculado >= 0 ? '+' : ''}${roi.roiCalculado.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${roi.investimento.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              Text(
                '→ R\$ ${roi.retorno.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConclusaoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0057FF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0057FF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: Color(0xFF0057FF), size: 16),
              SizedBox(width: 6),
              Text(
                'CONCLUSÃO TÉCNICA',
                style: TextStyle(
                  color: Color(0xFF0057FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            marketingCase.conclusao!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVendedorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: PremiumTokens.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marketingCase.nomeVendedor!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (marketingCase.telefoneVendedor != null)
                  Text(
                    marketingCase.telefoneVendedor!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PremiumTokens.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          if (marketingCase.telefoneVendedor != null)
            IconButton(
              icon: const Icon(Icons.phone_outlined),
              color: PremiumTokens.brandGreen,
              onPressed: () => HapticFeedback.lightImpact(),
            ),
        ],
      ),
    );
  }
}

class _MetricaItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricaItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
