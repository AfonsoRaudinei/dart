import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import 'comparativo_chart.dart';
import 'marketing_case_resultado_read_only_section.dart';
import 'marketing_case_story_entry_button.dart';
import 'marketing_comparativo_read_only_section.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

part 'marketing_case_sheet_avaliacao.dart';

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
      // DraggableScrollableSheet: preserve evita faixa preta acima do pane
      // (mesmo padrão de VisitSheet / map sheets).
      preserveMaterialDefaults: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarketingCaseSheet(marketingCase: marketingCase),
    );
  }

  /// Host usa [preserveMaterialDefaults]; Scope força isIos=false — detectar Azul via themeId.
  bool _isIosBlue(BuildContext context) =>
      Theme.of(context).extension<SoloForteThemeExtension>()?.themeId == 'blue';

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

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final isIos = _isIosBlue(context);
    final sheetBg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final sheetRadius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : Theme.of(context).dividerColor.withValues(alpha: 0.4);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;
    final hintColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final cardBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final cardBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : PremiumTokens.hairlineLight;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.45, 0.7, 0.95],
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
            border: isIos
                ? const Border(
                    top: BorderSide(color: SoloForteSheetSkinIos.sheetBorder),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle — área de arraste do DraggableScrollableSheet
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: isIos
                      ? SoloForteSheetSkinIos.handleSize.width
                      : 36,
                  height: isIos
                      ? SoloForteSheetSkinIos.handleSize.height
                      : 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Conteúdo scrollável — controller liga ao DSS
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
                            color: (isIos
                                    ? SoloForteSheetSkinIos.iconStroke
                                    : PremiumTokens.brandGreen)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _tipoLabel,
                            style: TextStyle(
                              color: isIos
                                  ? SoloForteSheetSkinIos.iconStroke
                                  : PremiumTokens.brandGreen,
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
                          ?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: hintColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            marketingCase.localizacaoTexto,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: hintColor),
                          ),
                        ),
                      ],
                    ),
                    if (marketingCase.dataCase != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDatePtBr(marketingCase.dataCase!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: hintColor),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Foto principal ─────────────────────────
                    if (marketingCase.fotoPrincipalUrl != null)
                      _buildFoto(marketingCase.fotoPrincipalUrl!, isIos),

                    // ── Métricas destaque ──────────────────────
                    _buildMetricasRow(context),
                    const SizedBox(height: 20),

                    // ── Produtor / Fazenda ─────────────────────
                    _buildInfoSection(
                      context,
                      'Produtor / Fazenda',
                      marketingCase.produtorFazenda,
                      titleColor: titleColor,
                      hintColor: hintColor,
                    ),
                    if (marketingCase.descricao != null) ...[
                      _buildInfoSection(
                        context,
                        'Descrição',
                        marketingCase.descricao!,
                        titleColor: titleColor,
                        hintColor: hintColor,
                      ),
                    ],

                    // ── Tipo Resultado: específico ─────────────
                    if (marketingCase.tipo == CaseTipo.resultado) ...[
                      MarketingCaseResultadoReadOnlySection(
                        marketingCase: marketingCase,
                      ),
                    ],

                    // ── Tipo Antes/Depois ──────────────────────
                    if (marketingCase.tipo == CaseTipo.antesDepois) ...[
                      if (marketingCase.parametros.isNotEmpty)
                        MarketingComparativoReadOnlySection(
                          parametros: marketingCase.parametros,
                          mediaGanhoPercent: marketingCase.mediaGanhoPercent,
                        )
                      else ...[
                        if (marketingCase.ganhoProdutividade != null)
                          _buildInfoSection(
                            context,
                            'Ganho de Produtividade',
                            marketingCase.ganhoProdutividade!,
                            titleColor: titleColor,
                            hintColor: hintColor,
                          ),
                        if (marketingCase.economiaGerada != null)
                          _buildInfoSection(
                            context,
                            'Economia Gerada',
                            marketingCase.economiaGerada!,
                            titleColor: titleColor,
                            hintColor: hintColor,
                          ),
                      ],
                      if (marketingCase.fotoAntesUrl != null ||
                          marketingCase.fotoDepoisUrl != null)
                        _buildAntesDepoisFotos(
                          context,
                          titleColor: titleColor,
                          isIos: isIos,
                        ),
                    ],

                    // ── Tipo Avaliação ─────────────────────────
                    if (marketingCase.tipo == CaseTipo.avaliacao) ...[
                      if (marketingCase.nomeTalhao != null) ...[
                        _buildInfoSection(
                          context,
                          'Talhão',
                          '${marketingCase.nomeTalhao!}${marketingCase.tamanhoHa != null ? ' — ${marketingCase.tamanhoHa!.toStringAsFixed(1)} ha' : ''}',
                          titleColor: titleColor,
                          hintColor: hintColor,
                        ),
                      ],
                      if (marketingCase.avaliacoesLivres.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAvaliacoesLivresList(
                          context,
                          hintColor: hintColor,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          titleColor: titleColor,
                          isIos: isIos,
                        ),
                      ],
                      if (marketingCase.conclusaoTecnica != null) ...[
                        const SizedBox(height: 12),
                        _buildConclusaoCard(context, titleColor: titleColor),
                      ],
                    ],

                    // ── Vendedor ───────────────────────────────
                    if (marketingCase.nomeVendedor != null) ...[
                      const SizedBox(height: 20),
                      _buildVendedorCard(
                        context,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        titleColor: titleColor,
                        hintColor: hintColor,
                        isIos: isIos,
                      ),
                    ],

                    const SizedBox(height: 24),
                    MarketingCaseStoryEntryButton(marketingCase: marketingCase),
                    const SizedBox(height: 80),
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

  Widget _buildFoto(String url, bool isIos) {
    final placeholderBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final placeholderIcon = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            height: 200,
            decoration: BoxDecoration(color: placeholderBg),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: placeholderIcon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricasRow(BuildContext context) {
    final items = <_MetricaItem>[];

    final resultadoRoi = marketingCase.computeRoi();
    if (resultadoRoi != null) {
      items.add(
        _MetricaItem(
          label: 'ROI/ha',
          value: _formatMoney(resultadoRoi.roiLiquidoRsHa),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF34C759),
        ),
      );
    } else if (marketingCase.produtividadeValor != null) {
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
                      item.label,
                      style: TextStyle(
                        color: item.color.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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

  Widget _buildInfoSection(
    BuildContext context,
    String label,
    String value, {
    required Color titleColor,
    required Color hintColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: hintColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntesDepoisFotos(
    BuildContext context, {
    required Color titleColor,
    required bool isIos,
  }) {
    return Row(
      children: [
        if (marketingCase.fotoAntesUrl != null)
          Expanded(
            child: Column(
              children: [
                _buildFotoMini(marketingCase.fotoAntesUrl!, isIos),
                const SizedBox(height: 4),
                Text(
                  'Antes',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        if (marketingCase.fotoDepoisUrl != null)
          Expanded(
            child: Column(
              children: [
                _buildFotoMini(marketingCase.fotoDepoisUrl!, isIos),
                const SizedBox(height: 4),
                Text(
                  'Depois',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isIos
                        ? SoloForteSheetSkinIos.iconStroke
                        : PremiumTokens.brandGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFotoMini(String url, bool isIos) {
    final placeholderBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final placeholderIcon = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          height: 130,
          decoration: BoxDecoration(color: placeholderBg),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: placeholderIcon,
          ),
        ),
      ),
    );
  }

  Widget _buildConclusaoCard(
    BuildContext context, {
    required Color titleColor,
  }) {
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
            marketingCase.conclusaoTecnica!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: titleColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendedorCard(
    BuildContext context, {
    required Color cardBg,
    required Color cardBorder,
    required Color titleColor,
    required Color hintColor,
    required bool isIos,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isIos ? null : PremiumTokens.brandGradient,
              color: isIos ? SoloForteSheetSkinIos.iconBackground : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: isIos ? SoloForteSheetSkinIos.iconStroke : Colors.white,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (marketingCase.telefoneVendedor != null)
                  Text(
                    marketingCase.telefoneVendedor!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hintColor,
                    ),
                  ),
              ],
            ),
          ),
          if (marketingCase.telefoneVendedor != null)
            IconButton(
              icon: const Icon(Icons.phone_outlined),
              color: isIos
                  ? SoloForteSheetSkinIos.iconStroke
                  : PremiumTokens.brandGreen,
              onPressed: () => HapticFeedback.lightImpact(),
            ),
        ],
      ),
    );
  }

  Widget _buildAvaliacoesLivresList(
    BuildContext context, {
    required Color hintColor,
    required Color cardBg,
    required Color cardBorder,
    required Color titleColor,
    required bool isIos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AVALIAÇÕES (${marketingCase.avaliacoesLivres.length})',
          style: TextStyle(
            color: hintColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...marketingCase.avaliacoesLivres.map(
          (avaliacao) => _AvaliacaoLivreReadOnlyCard(
            avaliacao: avaliacao,
            cardBg: cardBg,
            cardBorder: cardBorder,
            titleColor: titleColor,
            hintColor: hintColor,
            isIos: isIos,
          ),
        ),
      ],
    );
  }

  static String _formatDatePtBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
