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
import 'marketing_comparativo_read_only_section.dart';
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

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatSigned(double value) {
    final formatted = _formatNumber(value);
    return value >= 0 ? '+$formatted' : formatted;
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
                          ?.copyWith(
                            color: SoloForteSheetTokens.inputText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: SoloForteSheetTokens.inputHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            marketingCase.localizacaoTexto,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: SoloForteSheetTokens.inputHint,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (marketingCase.dataCase != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: SoloForteSheetTokens.inputHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDatePtBr(marketingCase.dataCase!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: SoloForteSheetTokens.inputHint,
                                ),
                          ),
                        ],
                      ),
                    ],
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
                      _buildResultadoRoiSection(context),
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
                          ),
                        if (marketingCase.economiaGerada != null)
                          _buildInfoSection(
                            context,
                            'Economia Gerada',
                            marketingCase.economiaGerada!,
                          ),
                      ],
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
                      if (marketingCase.avaliacoesLivres.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAvaliacoesLivresList(context),
                      ],
                      if (marketingCase.conclusaoTecnica != null) ...[
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
        child: CachedNetworkImage(
          imageUrl: url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            height: 200,
            decoration: const BoxDecoration(
              color: SoloForteSheetTokens.inputBackground,
            ),
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: SoloForteSheetTokens.inputHint,
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

  Widget _buildResultadoRoiSection(BuildContext context) {
    final roi = marketingCase.computeRoi();
    if (roi == null) return const SizedBox.shrink();
    final input = roi.input;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUTIVIDADE',
            style: TextStyle(
              color: SoloForteSheetTokens.inputHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Testemunha: ${_formatNumber(input.prodSemProduto)} ${input.unidadeProdutividade}   →   Com produto: ${_formatNumber(input.prodComProduto)} ${input.unidadeProdutividade}',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ganho: ${_formatSigned(roi.ganhoScHa)} ${input.unidadeProdutividade}',
            style: const TextStyle(
              fontSize: 14,
              color: PremiumTokens.brandGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ROI / RETORNO',
            style: TextStyle(
              color: SoloForteSheetTokens.inputHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Custo do produto: ${_formatMoney(input.custoProdutoPorHa)}/ha',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor do grão: ${_formatMoney(input.valorGrao)}/sc',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ROI líquido: ${_formatMoney(roi.roiLiquidoRsHa)}/ha (${_formatNumber(roi.roiEmSacasHa)} sc/ha)',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (roi.roiSacasTalhao != null && roi.roiReaisTalhao != null) ...[
            const SizedBox(height: 8),
            Text(
              'No talhão (${marketingCase.tamanhoHa!.toStringAsFixed(1)} ha): ${_formatNumber(roi.roiSacasTalhao!)} sc · ${_formatMoney(roi.roiReaisTalhao!)}',
              style: const TextStyle(
                color: SoloForteSheetTokens.inputText,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
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
              color: SoloForteSheetTokens.inputHint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SoloForteSheetTokens.inputText,
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
                  style: TextStyle(
                    color: SoloForteSheetTokens.inputText,
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
      child: CachedNetworkImage(
        imageUrl: url,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          height: 130,
          decoration: const BoxDecoration(
            color: SoloForteSheetTokens.inputBackground,
          ),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: SoloForteSheetTokens.inputHint,
          ),
        ),
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
            marketingCase.conclusaoTecnica!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SoloForteSheetTokens.inputText,
              height: 1.5,
            ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SoloForteSheetTokens.inputText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (marketingCase.telefoneVendedor != null)
                  Text(
                    marketingCase.telefoneVendedor!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SoloForteSheetTokens.inputHint,
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

  Widget _buildAvaliacoesLivresList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AVALIAÇÕES (${marketingCase.avaliacoesLivres.length})',
          style: const TextStyle(
            color: SoloForteSheetTokens.inputHint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...marketingCase.avaliacoesLivres.map(
          (avaliacao) => _AvaliacaoLivreReadOnlyCard(avaliacao: avaliacao),
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

class _AvaliacaoLivreReadOnlyCard extends StatefulWidget {
  final AvaliacaoItem avaliacao;

  const _AvaliacaoLivreReadOnlyCard({required this.avaliacao});

  @override
  State<_AvaliacaoLivreReadOnlyCard> createState() =>
      _AvaliacaoLivreReadOnlyCardState();
}

class _AvaliacaoLivreReadOnlyCardState
    extends State<_AvaliacaoLivreReadOnlyCard> {
  String? _selectedParametroId;

  @override
  Widget build(BuildContext context) {
    final avaliacao = widget.avaliacao;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${avaliacao.titulo.isEmpty ? 'Avaliação' : avaliacao.titulo} — ${avaliacao.nomeLadoA} vs ${avaliacao.nomeLadoB}',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Média de ganho: ${_formatSigned(avaliacao.mediaGanhoPercent)}%',
            style: const TextStyle(
              color: PremiumTokens.brandGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (avaliacao.cultura != null && avaliacao.cultura!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Cultura: ${avaliacao.cultura}',
              style: const TextStyle(
                color: SoloForteSheetTokens.inputHint,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...avaliacao.parametros.map(
            (parametro) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      parametro.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SoloForteSheetTokens.inputText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatValue(parametro.testemunha)} -> ${_formatValue(parametro.teste)}',
                    style: const TextStyle(
                      color: SoloForteSheetTokens.inputText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    parametro.testemunha == 0
                        ? '--'
                        : '${_formatSigned(parametro.deltaPercent)}%',
                    style: TextStyle(
                      color: parametro.isNegativo
                          ? PremiumTokens.alertError
                          : PremiumTokens.brandGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (avaliacao.parametros.isNotEmpty) ...[
            const SizedBox(height: 10),
            ComparativoChart(
              parametros: avaliacao.parametros,
              selecionadoId: _selectedParametroId,
              onSelect: (id) => setState(() => _selectedParametroId = id),
              testemunhaLabel: avaliacao.nomeLadoA,
              testeLabel: avaliacao.nomeLadoB,
            ),
          ],
          if (avaliacao.observacoes != null &&
              avaliacao.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              avaliacao.observacoes!,
              style: const TextStyle(
                color: SoloForteSheetTokens.inputText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatValue(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _formatSigned(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
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
