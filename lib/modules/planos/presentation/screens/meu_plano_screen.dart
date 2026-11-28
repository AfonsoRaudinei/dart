// ADR-012 — planos/presentation/screens/meu_plano_screen.dart
//
// Rota: /planos/meu-plano — status, vitrine da loja (preço/compra/troca), cores do metal.

import 'dart:async';
import 'package:soloforte_app/ui/components/premium/premium_page_title.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../data/services/loja_compra_gateway.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/enums/plano_tipo.dart';
import '../../domain/plano_cache_unavailable_exception.dart';
import '../../domain/store_plan_catalog.dart';
import '../meu_plano_vantagens.dart';
import '../plano_tipo_metal_colors.dart';
import '../providers/plano_providers.dart';

class MeuPlanoScreen extends ConsumerStatefulWidget {
  const MeuPlanoScreen({super.key});

  @override
  ConsumerState<MeuPlanoScreen> createState() => _MeuPlanoScreenState();
}

class _MeuPlanoScreenState extends ConsumerState<MeuPlanoScreen> {
  LojaVitrine? _vitrine;
  String? _aviso;
  bool _ocupado = false;
  bool _recarregando = false;
  StreamSubscription<LojaCompraAviso>? _avisos;

  @override
  void initState() {
    super.initState();
    final gateway = ref.read(lojaCompraGatewayProvider);
    _avisos = gateway.avisos.listen((aviso) {
      if (!mounted) return;
      setState(() => _aviso = aviso.mensagem);
      if (aviso.concedido) ref.invalidate(planoAtivoProvider);
    });
    _carregarLoja();
  }

  Future<void> _carregarLoja() async {
    try {
      final vitrine = await ref.read(lojaCompraGatewayProvider).carregar();
      if (!mounted) return;
      setState(() => _vitrine = vitrine);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vitrine = const LojaVitrine(
          disponivel: false,
          produtos: [],
          motivoIndisponivel: LojaMotivoIndisponivel.erroConsulta,
        );
        _aviso = 'Não foi possível carregar os planos da loja.';
      });
    }
  }

  Future<void> _recarregarLoja() async {
    if (_recarregando) return;
    setState(() {
      _recarregando = true;
      _aviso = null;
    });
    await _carregarLoja();
    if (mounted) setState(() => _recarregando = false);
  }

  @override
  void dispose() {
    _avisos?.cancel();
    super.dispose();
  }

  Future<void> _comprar(String productId) async {
    setState(() => _ocupado = true);
    try {
      await ref.read(lojaCompraGatewayProvider).comprar(productId);
    } catch (_) {
      if (mounted) setState(() => _aviso = 'A loja não iniciou a compra.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planoAsync = ref.watch(planoAtivoProvider);

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: planoAsync.when(
                data: (plano) => _PlanoAtivoContent(
                  plano: plano,
                  vitrine: _vitrine,
                  aviso: _aviso,
                  ocupado: _ocupado,
                  recarregando: _recarregando,
                  onComprar: _comprar,
                  onRecarregar: () {
                    HapticFeedback.lightImpact();
                    _recarregarLoja();
                  },
                  onRestaurar: () {
                    HapticFeedback.lightImpact();
                    ref.read(lojaCompraGatewayProvider).restaurar();
                  },
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                error: (e, _) => _ErrorContent(
                  error: e,
                  onRetry: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(planoAtivoProvider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [Text('Meu Plano', style: premiumPageTitleStyle(context))],
      ),
    );
  }
}

class _PlanoAtivoContent extends ConsumerStatefulWidget {
  final UserPlan plano;
  final LojaVitrine? vitrine;
  final String? aviso;
  final bool ocupado;
  final bool recarregando;
  final Future<void> Function(String productId) onComprar;
  final VoidCallback onRecarregar;
  final VoidCallback onRestaurar;

  const _PlanoAtivoContent({
    required this.plano,
    required this.vitrine,
    required this.aviso,
    required this.ocupado,
    required this.recarregando,
    required this.onComprar,
    required this.onRecarregar,
    required this.onRestaurar,
  });

  @override
  ConsumerState<_PlanoAtivoContent> createState() => _PlanoAtivoContentState();
}

class _PlanoAtivoContentState extends ConsumerState<_PlanoAtivoContent> {
  late MeuPlanoMenu _menu;

  @override
  void initState() {
    super.initState();
    _menu = MeuPlanoMenu.doPlano(widget.plano);
  }

  @override
  void didUpdateWidget(covariant _PlanoAtivoContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final plano = widget.plano;
    final anterior = oldWidget.plano;
    if (anterior.id != plano.id || anterior.plano != plano.plano) {
      _menu = MeuPlanoMenu.doPlano(plano);
    }
  }

  bool get _semPlanoPago => widget.plano.id == 'free';

  LojaProduto? _produtoDoMenu(LojaVitrine vitrine) {
    final sufixo = _menu.sufixoProduto;
    if (sufixo == null) return null;
    for (final produto in vitrine.produtos) {
      if (produto.productId.endsWith(sufixo)) return produto;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final plano = widget.plano;
    final vitrine = widget.vitrine;
    final aviso = widget.aviso;
    final ocupado = widget.ocupado;
    final onComprar = widget.onComprar;
    final onRestaurar = widget.onRestaurar;
    final expiraEmBreve = plano.expiraEmBreve;
    final codigoAsync = ref.watch(meuCodigoIndicacaoProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final metal = _semPlanoPago
        ? primary
        : PlanoTipoMetalColors.forTipo(plano.plano);
    final vitrineLocal = vitrine;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      children: [
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(_semPlanoPago ? 18 : 24),
          decoration: BoxDecoration(
            color: context.premiumSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _semPlanoPago
                  ? context.premiumCardBorder
                  : metal.withValues(alpha: 0.35),
            ),
            boxShadow: context.premiumCardShadows,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PlanoTipoMetalColors.badgeBackground(metal),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: metal,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _semPlanoPago ? 'Sem plano pago' : 'Plano ${plano.plano.label}',
                style: TextStyle(
                  // Plano pago é conquista (destaque grande na cor do metal);
                  // sem plano, o foco é a ação: ver os planos abaixo.
                  fontSize: _semPlanoPago ? 20 : 28,
                  fontWeight: _semPlanoPago ? FontWeight.w600 : FontWeight.w700,
                  color: _semPlanoPago ? context.premiumTextPrimary : metal,
                  letterSpacing: -0.4,
                ),
              ),
              if (_semPlanoPago) ...[
                const SizedBox(height: 6),
                Text(
                  'Veja os planos abaixo e libere mais recursos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.premiumTextSecondary,
                  ),
                ),
              ],
              if (!_semPlanoPago) ...[
                const SizedBox(height: 8),
                Text(
                  'via ${plano.origem.label}',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.premiumTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!_semPlanoPago) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.premiumSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: expiraEmBreve
                    ? Colors.red.withAlpha(120)
                    : context.premiumCardBorder,
              ),
              boxShadow: context.premiumCardShadows,
            ),
            child: Row(
              children: [
                Icon(
                  expiraEmBreve
                      ? Icons.warning_amber_rounded
                      : Icons.calendar_today_rounded,
                  color: expiraEmBreve ? Colors.red : metal,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expiraEmBreve
                            ? '⚠️ Expira em ${plano.diasRestantes} dias'
                            : plano.diasRestantesLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: expiraEmBreve
                              ? Colors.red
                              : context.premiumTextPrimary,
                        ),
                      ),
                      if (!plano.isIndefinite)
                        Text(
                          'Expira em ${_formatDate(plano.expiraEm)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.premiumTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: 'Cases ativos no mapa',
          value: plano.limiteCasesLabel,
          accent: metal,
        ),
        if (plano.plano != PlanoTipo.ouro) ...[
          const SizedBox(height: 16),
          _NavigationRow(
            icon: Icons.group_add_outlined,
            label: 'Indicações',
            value: _buildIndicacaoSubtitle(
              plano,
              codigoAsync.asData?.value?.indicacoesValidadas ?? 0,
            ),
            route: AppRoutes.planosIndicacoes,
            accent: metal,
          ),
        ],
        const SizedBox(height: 24),
        if (vitrineLocal == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Planos',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.premiumTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          MeuPlanoMenuBar(
            selecionado: _menu,
            primaria: primary,
            onSelecionar: (menu) {
              if (menu == _menu) return;
              HapticFeedback.lightImpact();
              setState(() => _menu = menu);
            },
          ),
          const SizedBox(height: 12),
          MeuPlanoVantagensCard(
            menu: _menu,
            primaria: primary,
            vitrine: vitrineLocal,
          ),
          if (_menu.productIdLoja case final productId?) ...[
            const SizedBox(height: 12),
            _ProdutoLojaRow(
              offer: storePlanOfferFor(productId)!,
              produto: _produtoDoMenu(vitrineLocal),
              motivo: vitrineLocal.motivoIndisponivel,
              plano: plano,
              semPlanoPago: _semPlanoPago,
              ocupado: ocupado,
              recarregando: widget.recarregando,
              onComprar: () => onComprar(productId),
              onRecarregar: widget.onRecarregar,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'O valor é definido pela App Store ou Google Play, cobrado à vista '
            'na confirmação da compra. O acesso dura o prazo do plano e não '
            'renova automaticamente. Ao mudar de plano, um novo prazo começa.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: context.premiumTextSecondary,
            ),
          ),
          if (aviso != null) ...[
            const SizedBox(height: 12),
            Text(
              aviso,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.premiumTextSecondary,
              ),
            ),
          ],
          if (vitrineLocal.disponivel) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: ocupado ? null : onRestaurar,
                child: Text(
                  'Restaurar compras',
                  style: TextStyle(color: primary),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 32),
        const SizedBox(height: kFabSafeArea),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _buildIndicacaoSubtitle(UserPlan plano, int indicacoesValidadas) {
    switch (plano.plano) {
      case PlanoTipo.bronze:
        return '$indicacoesValidadas/5 para Prata';
      case PlanoTipo.prata:
        return '$indicacoesValidadas/10 para Ouro';
      case PlanoTipo.ouro:
        return '';
    }
  }
}

class _ProdutoLojaRow extends StatelessWidget {
  const _ProdutoLojaRow({
    required this.offer,
    required this.produto,
    required this.motivo,
    required this.plano,
    required this.semPlanoPago,
    required this.ocupado,
    required this.recarregando,
    required this.onComprar,
    required this.onRecarregar,
  });

  final StorePlanOffer offer;
  final LojaProduto? produto;
  final LojaMotivoIndisponivel? motivo;
  final UserPlan plano;
  final bool semPlanoPago;
  final bool ocupado;
  final bool recarregando;
  final VoidCallback onComprar;
  final VoidCallback onRecarregar;

  PlanoTipo get _tipoProduto =>
      PlanoTipo.values.firstWhere((t) => offer.productId.endsWith(t.name));

  bool get _mesmoPlano => _tipoProduto == plano.plano;

  bool get _isAtual =>
      !semPlanoPago && !plano.expirado && plano.ativo && _mesmoPlano;

  bool get _mostrarPrecoCompra =>
      semPlanoPago || (plano.expirado && _mesmoPlano);

  String get _textoIndisponivel => switch (motivo) {
    LojaMotivoIndisponivel.lojaFechada =>
      'A loja não está disponível neste aparelho. '
          'Verifique sua conexão e conta da loja.',
    _ =>
      'Este plano ainda não está disponível na loja. '
          'Tente atualizar em instantes.',
  };

  @override
  Widget build(BuildContext context) {
    final metal = PlanoTipoMetalColors.forTipo(_tipoProduto);
    final item = produto;

    Widget? acao;
    Widget? compra;
    if (_isAtual) {
      acao = Text(
        'Atual',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.premiumTextSecondary,
        ),
      );
    } else if (_mostrarPrecoCompra) {
      compra = _LojaCompraButton(
        key: const Key('meu_plano_comprar'),
        label: item == null ? 'Comprar' : 'Comprar · ${item.preco}',
        color: metal,
        enabled: item != null && !ocupado,
        onPressed: onComprar,
      );
    } else {
      acao = _LojaAcaoButton(
        label: 'Mudar',
        color: metal,
        enabled: item != null && !ocupado,
        onPressed: onComprar,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: metal.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: metal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: metal,
                        ),
                      ),
                    ),
                    if (acao != null) acao,
                  ],
                ),
                Text(
                  '${offer.prazo} · pagamento único',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.premiumTextSecondary,
                  ),
                ),
                if (compra != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: compra),
                ],
                if (item == null && !_isAtual) ...[
                  const SizedBox(height: 8),
                  Text(
                    _textoIndisponivel,
                    key: const Key('meu_plano_motivo_indisponivel'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: context.premiumTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (recarregando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    TextButton(
                      key: const Key('meu_plano_recarregar_loja'),
                      onPressed: onRecarregar,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Atualizar planos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LojaCompraButton extends StatelessWidget {
  const _LojaCompraButton({
    super.key,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return FilledButton(
      onPressed: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _LojaAcaoButton extends StatelessWidget {
  const _LojaAcaoButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorContent({required this.error, required this.onRetry});

  static String mensagemPara(Object error) {
    if (isPlanoSessionOrRlsError(error)) {
      return 'Sua sessão precisa ser renovada. Tente novamente.';
    }
    return 'Não foi possível carregar seu plano agora. '
        'Verifique a conexão e tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, kFabSafeArea),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: context.premiumTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              mensagemPara(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.premiumTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('meu_plano_retry'),
              onPressed: onRetry,
              child: Text(
                'Tentar novamente',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.premiumCardBorder),
        boxShadow: context.premiumCardShadows,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: context.premiumTextPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.premiumTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String route;
  final Color accent;

  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.route,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.premiumSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.premiumCardBorder),
      ),
      shadowColor: const Color(0x1F000000),
      elevation: context.isPremiumDark ? 0 : 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.premiumTextPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.premiumTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: context.premiumTextSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
