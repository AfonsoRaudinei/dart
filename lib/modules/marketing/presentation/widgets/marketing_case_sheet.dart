import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader_provider.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/marketing_case_status.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/marketing_case_access_policy.dart';
import '../providers/marketing_providers.dart';
import 'comparativo_chart.dart';
import 'marketing_case_edit_sheet.dart';
import 'marketing_case_result_hero.dart';
import 'marketing_comparativo_read_only_section.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

/// Bottom Sheet de detalhe do pin de Marketing (ADR-048).
///
/// Layout: um único [showSoloForteSheet] (sem DraggableScrollableSheet aninhado).
/// Público: só hero de resultado. Autenticado: detalhes + ações ACL.
class MarketingCaseSheet extends ConsumerStatefulWidget {
  final MarketingCase marketingCase;
  final bool isPublicSurface;

  const MarketingCaseSheet({
    super.key,
    required this.marketingCase,
    this.isPublicSurface = false,
  });

  static void show(
    BuildContext context,
    MarketingCase marketingCase, {
    bool isPublicSurface = false,
  }) {
    HapticFeedback.lightImpact();
    showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      maxHeightFraction: 0.92,
      builder: (_) => MarketingCaseSheet(
        marketingCase: marketingCase,
        isPublicSurface: isPublicSurface,
      ),
    );
  }

  @override
  ConsumerState<MarketingCaseSheet> createState() => _MarketingCaseSheetState();
}

class _MarketingCaseSheetState extends ConsumerState<MarketingCaseSheet> {
  late MarketingCase _case;

  @override
  void initState() {
    super.initState();
    _case = widget.marketingCase;
  }

  String get _tipoLabel {
    switch (_case.tipo) {
      case CaseTipo.resultado:
        return 'Resultado';
      case CaseTipo.antesDepois:
        return 'Antes/Depois';
      case CaseTipo.avaliacao:
        return 'Avaliação';
    }
  }

  Color get _planoColor {
    switch (_case.visibilidade) {
      case PlanoMarketing.ouro:
        return const Color(0xFFFFB800);
      case PlanoMarketing.prata:
        return const Color(0xFF9EA9B2);
      case PlanoMarketing.bronze:
        return const Color(0xFFA0522D);
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

  Future<Set<String>> _resolveLinkedClientIds() async {
    final role = ref.read(currentUserRoleProvider);
    if (role.isProdutor) {
      return ref.read(authorizedClientIdsProvider).valueOrNull ?? const {};
    }
    try {
      final clients = await ref.read(clientLookupProvider).listAtivos();
      return clients.map((c) => c.id).toSet();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _onEdit({required bool asProposal}) async {
    final currentUserId = LocalSessionIdentity.resolveUserId();
    await MarketingCaseEditSheet.show(
      context: context,
      initial: _case,
      asProposal: asProposal,
      onSubmit: (updated) async {
        final notifier = ref.read(marketingCasesProvider.notifier);
        final MarketingCase? result;
        if (asProposal) {
          result = await notifier.proposeEdit(
            current: _case,
            proposed: updated,
          );
        } else {
          result = await notifier.updateCase(
            MarketingCase.fromJson({
              ...updated.toJson(),
              'user_id': _case.ownerUserId ?? currentUserId,
              'status': MarketingCaseStatus.published.toValue(),
            }),
          );
        }
        if (result != null && mounted) {
          setState(() => _case = result!);
        }
      },
    );
  }

  Future<void> _onSoftDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir case?'),
        content: const Text(
          'O case será removido do mapa e sincronizado depois. Esta ação não apaga o histórico remoto de forma definitiva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(marketingCasesProvider.notifier)
        .softDeleteCase(_case);
    if (!mounted) return;
    if (deleted != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case excluído localmente.')),
      );
    }
  }

  Future<void> _onApprove() async {
    final result = await ref
        .read(marketingCasesProvider.notifier)
        .approvePendingEdit(_case);
    if (result != null && mounted) setState(() => _case = result);
  }

  Future<void> _onReject() async {
    final result = await ref
        .read(marketingCasesProvider.notifier)
        .rejectPendingEdit(_case);
    if (result != null && mounted) setState(() => _case = result);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = LocalSessionIdentity.resolveUserId();
    final isPublic =
        widget.isPublicSurface || currentUserId.isEmpty;

    return SafeArea(
      top: false,
      child: FutureBuilder<Set<String>>(
        future: isPublic ? Future.value(const <String>{}) : _resolveLinkedClientIds(),
        builder: (context, snapshot) {
          final linked = snapshot.data ?? const <String>{};
          final canEdit = !isPublic &&
              MarketingCaseAccessPolicy.canEditDirect(
                marketingCase: _case,
                currentUserId: currentUserId,
              );
          final canPropose = !isPublic &&
              MarketingCaseAccessPolicy.canProposeEdit(
                marketingCase: _case,
                currentUserId: currentUserId,
                linkedClientIds: linked,
              );
          final canApprove = !isPublic &&
              MarketingCaseAccessPolicy.canApproveEdit(
                marketingCase: _case,
                currentUserId: currentUserId,
              );
          final canDelete = !isPublic &&
              MarketingCaseAccessPolicy.canSoftDelete(
                marketingCase: _case,
                currentUserId: currentUserId,
              );

          return ListView(
            padding: const EdgeInsets.only(bottom: kFabSafeArea),
            children: [
              MarketingCaseResultHero(marketingCase: _case),
              if (!isPublic) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildBadgesRow(),
                ),
                if (_case.status == MarketingCaseStatus.pendingApproval)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildPendingBanner(canApprove: canApprove),
                  ),
                if (canEdit || canPropose || canDelete || canApprove)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildActions(
                      canEdit: canEdit,
                      canPropose: canPropose,
                      canDelete: canDelete,
                      canApprove: canApprove,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoSection(
                        context,
                        'Produtor / Fazenda',
                        _case.produtorFazenda,
                      ),
                      if (_case.descricao != null)
                        _buildInfoSection(context, 'Descrição', _case.descricao!),
                      if (_case.tipo == CaseTipo.resultado)
                        _buildResultadoRoiSection(context),
                      if (_case.tipo == CaseTipo.antesDepois) ...[
                        if (_case.parametros.isNotEmpty)
                          MarketingComparativoReadOnlySection(
                            parametros: _case.parametros,
                            mediaGanhoPercent: _case.mediaGanhoPercent,
                          )
                        else ...[
                          if (_case.ganhoProdutividade != null)
                            _buildInfoSection(
                              context,
                              'Ganho de Produtividade',
                              _case.ganhoProdutividade!,
                            ),
                          if (_case.economiaGerada != null)
                            _buildInfoSection(
                              context,
                              'Economia Gerada',
                              _case.economiaGerada!,
                            ),
                        ],
                      ],
                      if (_case.tipo == CaseTipo.avaliacao) ...[
                        if (_case.nomeTalhao != null)
                          _buildInfoSection(
                            context,
                            'Talhão',
                            '${_case.nomeTalhao!}${_case.tamanhoHa != null ? ' — ${_case.tamanhoHa!.toStringAsFixed(1)} ha' : ''}',
                          ),
                        if (_case.avaliacoesLivres.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildAvaliacoesLivresList(context),
                        ],
                        if (_case.conclusaoTecnica != null) ...[
                          const SizedBox(height: 12),
                          _buildConclusaoCard(context),
                        ],
                      ],
                      if (_case.nomeVendedor != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoSection(
                          context,
                          'Vendedor',
                          _case.nomeVendedor!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgesRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _planoColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _planoColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            _case.visibilidade.name.toUpperCase(),
            style: TextStyle(
              color: _planoColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: PremiumTokens.brandGreen.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildPendingBanner({required bool canApprove}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        canApprove
            ? 'Há uma edição pendente de aprovação.'
            : 'Edição enviada — aguardando aprovação do autor.',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActions({
    required bool canEdit,
    required bool canPropose,
    required bool canDelete,
    required bool canApprove,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canApprove) ...[
          FilledButton(
            onPressed: _onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: PremiumTokens.brandGreen,
            ),
            child: const Text('Aprovar edição'),
          ),
          OutlinedButton(
            onPressed: _onReject,
            child: const Text('Rejeitar'),
          ),
        ],
        if (canEdit)
          OutlinedButton(
            onPressed: () => _onEdit(asProposal: false),
            child: const Text('Editar'),
          ),
        if (canPropose)
          OutlinedButton(
            onPressed: () => _onEdit(asProposal: true),
            child: const Text('Sugerir edição'),
          ),
        if (canDelete)
          OutlinedButton(
            onPressed: _onSoftDelete,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Excluir'),
          ),
      ],
    );
  }

  Widget _buildResultadoRoiSection(BuildContext context) {
    final roi = _case.computeRoi();
    if (roi == null) return const SizedBox.shrink();
    final input = roi.input;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
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
          const Text(
            'CONCLUSÃO TÉCNICA',
            style: TextStyle(
              color: Color(0xFF0057FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _case.conclusaoTecnica!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SoloForteSheetTokens.inputText,
              height: 1.5,
            ),
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
          'AVALIAÇÕES (${_case.avaliacoesLivres.length})',
          style: const TextStyle(
            color: SoloForteSheetTokens.inputHint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ..._case.avaliacoesLivres.map(
          (avaliacao) => _AvaliacaoLivreReadOnlyCard(avaliacao: avaliacao),
        ),
      ],
    );
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
        ],
      ),
    );
  }

  static String _formatSigned(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
  }
}
