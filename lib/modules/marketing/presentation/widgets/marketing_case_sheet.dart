import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../theme/plano_marketing_visual.dart';
import 'comparativo_chart.dart';
import 'marketing_case_resultado_read_only_section.dart';
import 'marketing_case_story_entry_button.dart';
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
      // Fundo transparente: o pane do DraggableScrollableSheet pinta só a
      // fração visível — evita faixa preta acima do handle (padrão map sheets).
      backgroundColor: Colors.transparent,
      builder: (_) => MarketingCaseSheet(marketingCase: marketingCase),
    );
  }

  Color get _planoColor => marketingCase.visibilidade.color;

  IconData get _planoIcon => marketingCase.visibilidade.icon;

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
    // Sinal antes da moeda: "-R$ 595,00", não "R$ -595,00".
    final absoluto = NumberFormat('#,##0.00', 'pt_BR').format(value.abs());
    return '${value < 0 ? '-' : ''}R\$ $absoluto';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.7, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: SoloForteSheetTokens.sheetBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SoloForteSheetTokens.borderRadius),
            ),
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
                    color: SoloForteSheetTokens.divider,
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
                        // Tipo — categoria, não valor: fica neutro para não
                        // competir com o verde do número de resultado.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SoloForteSheetTokens.inputBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _tipoLabel,
                            style: const TextStyle(
                              color: SoloForteSheetTokens.inputHint,
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
                    const SizedBox(height: 6),
                    // Identificação do case em uma linha só: quem, onde,
                    // quando. Antes o produtor ficava numa seção solta lá
                    // embaixo, depois das métricas.
                    Text(
                      _subtitulo(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SoloForteSheetTokens.inputHint,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Foto principal ─────────────────────────
                    if (marketingCase.fotoPrincipalUrl != null)
                      _buildFoto(marketingCase.fotoPrincipalUrl!),

                    // ── Métricas destaque ──────────────────────
                    _buildMetricasRow(context),
                    const SizedBox(height: 20),

                    if (marketingCase.descricao != null) ...[
                      _buildInfoSection(
                        context,
                        'Descrição',
                        marketingCase.descricao!,
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

  /// Bloco de resultado: um número herói e as demais métricas como linhas.
  /// Antes eram caixas coloridas lado a lado, cada uma com sua cor, todas
  /// disputando a mesma atenção — o valor do case não se destacava.
  Widget _buildMetricasRow(BuildContext context) {
    final items = <_MetricaItem>[];

    final resultadoRoi = marketingCase.computeRoi();
    if (resultadoRoi != null) {
      items.add(
        _MetricaItem(
          label: 'ROI líquido por hectare',
          value: _formatMoney(resultadoRoi.roiLiquidoRsHa),
          negativo: resultadoRoi.roiLiquidoRsHa < 0,
        ),
      );
    } else if (marketingCase.produtividadeValor != null) {
      items.add(
        _MetricaItem(
          label: 'Produtividade',
          value:
              '${marketingCase.produtividadeValor!.toStringAsFixed(1)} ${marketingCase.produtividadeUnidade?.toValue() ?? ''}',
        ),
      );
    }
    if (marketingCase.economiaGerada != null) {
      items.add(
        _MetricaItem(
          label: 'Economia gerada',
          value: marketingCase.economiaGerada!,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final destaque = items.first;
    final secundarias = items.skip(1).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SoloForteSheetTokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            destaque.value,
            style: TextStyle(
              // Verde é afirmação de ganho: um resultado negativo não pode
              // sair pintado de verde só porque é o número herói.
              color: destaque.negativo
                  ? PremiumTokens.alertError
                  : PremiumTokens.brandGreen,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destaque.label,
            style: const TextStyle(
              color: SoloForteSheetTokens.inputHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          for (final item in secundarias) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: PremiumTokens.hairlineThickness,
                thickness: PremiumTokens.hairlineThickness,
                color: SoloForteSheetTokens.divider,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // economiaGerada é texto livre: rótulo e valor precisam
                // ceder espaço um ao outro em vez de estourar a linha.
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: SoloForteSheetTokens.inputHint,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item.value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: SoloForteSheetTokens.inputText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _subtitulo() {
    final partes = <String>[
      marketingCase.produtorFazenda.trim(),
      marketingCase.localizacaoTexto.trim(),
      if (marketingCase.dataCase != null)
        _formatDatePtBr(marketingCase.dataCase!),
    ].where((parte) => parte.isNotEmpty);
    return partes.join(' · ');
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
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SoloForteSheetTokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONCLUSÃO TÉCNICA',
            style: TextStyle(
              color: SoloForteSheetTokens.inputHint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
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
        border: Border.all(color: SoloForteSheetTokens.divider),
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
              tooltip: 'Ligar para o responsável',
              onPressed: () => _ligarPara(marketingCase.telefoneVendedor!),
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

  /// Mesmo padrão de contato do detalhe de cliente: `tel:` via url_launcher.
  /// Antes o botão só vibrava — não ligava para ninguém.
  static Future<void> _ligarPara(String telefone) async {
    HapticFeedback.lightImpact();
    final digits = telefone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
        border: Border.all(color: SoloForteSheetTokens.divider),
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
  final bool negativo;

  const _MetricaItem({
    required this.label,
    required this.value,
    this.negativo = false,
  });
}
