import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

/// Política do seletor **Visibilidade** (metal da publicação) — docs/case.md.
class MarketingVisibilityPolicy {
  const MarketingVisibilityPolicy._();

  /// Sem plano pago ou plano expirado/inativo (não admin): seletor travado, sem seleção na UI.
  static bool seletorTotalmenteTravado(UserPlan plan) {
    if (plan.isAdmin) return false;
    return plan.id == 'free' || plan.ocultaPinsMarketingNoMapa;
  }

  /// Metais que o usuário pode escolher no seletor (vazio = todos visíveis, nenhum tocável).
  static Set<PlanoMarketing> metaisSelecionaveis(UserPlan plan) {
    if (seletorTotalmenteTravado(plan)) return const {};
    if (plan.isAdmin) {
      return PlanoMarketing.values.toSet();
    }
    switch (plan.plano) {
      case PlanoTipo.bronze:
        return {PlanoMarketing.bronze};
      case PlanoTipo.prata:
        return {PlanoMarketing.bronze, PlanoMarketing.prata};
      case PlanoTipo.ouro:
        return PlanoMarketing.values.toSet();
    }
  }

  /// Metal inicial ao abrir **Novo case**; `null` quando o seletor está totalmente travado.
  static PlanoMarketing? metalInicialNovoCase(UserPlan plan) {
    if (seletorTotalmenteTravado(plan)) return null;
    const ordem = [
      PlanoMarketing.bronze,
      PlanoMarketing.prata,
      PlanoMarketing.ouro,
    ];
    final enabled = metaisSelecionaveis(plan);
    for (final metal in ordem) {
      if (enabled.contains(metal)) return metal;
    }
    return null;
  }

  /// Valor técnico ao persistir rascunho sem metal escolhido na UI (conta free / travada).
  static PlanoMarketing valorTecnicoSemSelecaoUi() => PlanoMarketing.bronze;

  /// Fim da janela pública conforme migration Supabase (meses por tier).
  static DateTime publicoAteParaMetal(
    PlanoMarketing metal,
    DateTime liberadoEm,
  ) {
    final utc = liberadoEm.toUtc();
    final months = switch (metal) {
      PlanoMarketing.ouro => 6,
      PlanoMarketing.prata => 4,
      PlanoMarketing.bronze => 2,
    };
    return DateTime.utc(
      utc.year,
      utc.month + months,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
      utc.microsecond,
    );
  }

  /// Sem [MarketingCase.liberadoEm]: pin restrito ao autor.
  ///
  /// Retorna `true` quando o case ainda não foi liberado com plano pago
  /// (`liberado_em` nulo). [currentUserId] é reservado para extensões futuras.
  static bool somenteAutorNoMapa(
    MarketingCase marketingCase,
    String currentUserId,
  ) {
    return marketingCase.liberadoEm == null;
  }

  /// Janela pública ativa (após liberação). `publico_ate` nulo = ainda ativa.
  static bool janelaPublicaAtiva(
    MarketingCase marketingCase, {
    DateTime? reference,
  }) {
    if (marketingCase.liberadoEm == null) return false;
    final ate = marketingCase.publicoAte;
    if (ate == null) return true;
    final now = (reference ?? DateTime.now()).toUtc();
    return ate.toUtc().isAfter(now);
  }
}