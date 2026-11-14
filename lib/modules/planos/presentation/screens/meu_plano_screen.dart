// ADR-012 — planos/presentation/screens/meu_plano_screen.dart
//
// Rota: /planos/meu-plano — status, vitrine da loja (preço/compra/troca), cores do metal.

import 'dart:async';

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
        _vitrine = LojaVitrine.indisponivel;
        _aviso = 'Não foi possível carregar os planos da loja.';
      });
    }
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
                  onComprar: _comprar,
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
                error: (e, _) => _ErrorContent(error: e.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Text(
            'Meu Plano',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.premiumTextPrimary,
              letterSpacing: 0.37,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanoAtivoContent extends ConsumerStatefulWidget {
  final UserPlan plano;
  final LojaVitrine? vitrine;
  final String? aviso;
  final bool ocupado;
  final Future<void> Function(String productId) onComprar;
  final VoidCallback onRestaurar;

  const _PlanoAtivoContent({
    required this.plano,
    required this.vitrine,
    required this.aviso,
    required this.ocupado,
    required this.onComprar,
    required this.onRestaurar,
  });

  @override
  ConsumerState<_PlanoAtivoContent> createState() => _PlanoAtivoContentState();
}

class _PlanoAtivoContentState extends ConsumerState<_PlanoAtivoContent> {
  late _PlanoMenu _menu;

  @override
  void initState() {
    super.initState();
    _menu = _PlanoMenu.doPlano(widget.plano);
  }

  @override
  void didUpdateWidget(covariant _PlanoAtivoContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final plano = widget.plano;
    final anterior = oldWidget.plano;
    if (anterior.id != plano.id || anterior.plano != plano.plano) {
      _menu = _PlanoMenu.doPlano(plano);
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.premiumSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _semPlanoPago
                  ? context.premiumHairline
                  : metal.withValues(alpha: 0.35),
            ),
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
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _semPlanoPago ? context.premiumTextPrimary : metal,
                  letterSpacing: -0.4,
                ),
              ),
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
                    : context.premiumHairline,
              ),
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
          _MenuPlanos(
            selecionado: _menu,
            primaria: primary,
            onSelecionar: (menu) {
              if (menu == _menu) return;
              HapticFeedback.lightImpact();
              setState(() => _menu = menu);
            },
          ),
          const SizedBox(height: 12),
          _VantagensPlano(menu: _menu, primaria: primary),
          if (_produtoDoMenu(vitrineLocal) case final produto?) ...[
            const SizedBox(height: 12),
            _ProdutoLojaRow(
              produto: produto,
              plano: plano,
              semPlanoPago: _semPlanoPago,
              ocupado: ocupado,
              onComprar: () => onComprar(produto.productId),
            ),
          ],
          if (vitrineLocal.produtos.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'A loja não tem planos disponíveis para compra neste momento.',
              style: TextStyle(
                fontSize: 15,
                color: context.premiumTextSecondary,
              ),
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

enum _PlanoMenu {
  gratis,
  bronze,
  prata,
  ouro;

  static const _titulos = ['Grátis', 'Bronze', 'Prata', 'Ouro'];

  static _PlanoMenu doPlano(UserPlan plano) {
    if (plano.id == 'free') return gratis;
    return switch (plano.plano) {
      PlanoTipo.bronze => bronze,
      PlanoTipo.prata => prata,
      PlanoTipo.ouro => ouro,
    };
  }

  String get titulo => _titulos[index];

  /// Sufixo do productId da loja. Grátis não tem compra.
  String? get sufixoProduto => switch (this) {
    gratis => null,
    bronze => '_bronze',
    prata => '_prata',
    ouro => '_ouro',
  };

  Color cor(Color primaria) => switch (this) {
    gratis => primaria,
    bronze => PlanoTipoMetalColors.bronze,
    prata => PlanoTipoMetalColors.prata,
    ouro => PlanoTipoMetalColors.ouro,
  };

  List<String> get vantagens => switch (this) {
    gratis => const [
      'Seu case fica no mapa. Só você vê.',
      'O seletor de metal aparece travado.',
      'Você cria ocorrência. Ela não vai para o produtor.',
      'O vínculo leva fazenda, talhões, mapa e desenhos.',
    ],
    bronze => const [
      'R\$ 30 por mês, por 3 meses.',
      '5 cases no metal Bronze.',
      'O pin aparece para você e para o produtor do vínculo, a partir do zoom 14.',
      'Você compartilha ocorrência.',
      '5 indicações sobem para Prata.',
    ],
    prata => const [
      'R\$ 50 por mês, por 6 meses.',
      '5 cases Bronze e 5 cases Prata.',
      'O pin Prata aparece para quem está logado, a partir do zoom 12.',
      'Você compartilha o case no vínculo.',
      '10 indicações sobem para Ouro.',
    ],
    ouro => const [
      'R\$ 80 por mês, por 12 meses.',
      '5 cases Bronze, 5 Prata e 10 Ouro.',
      'O pin Ouro aparece para todos, mesmo sem login, a partir do zoom 10.',
      'O produtor pode publicar o mesmo case. No mapa fica o pin mais alto.',
      'NDVI refinado.',
    ],
  };
}

class _MenuPlanos extends StatelessWidget {
  const _MenuPlanos({
    required this.selecionado,
    required this.primaria,
    required this.onSelecionar,
  });

  final _PlanoMenu selecionado;
  final Color primaria;
  final ValueChanged<_PlanoMenu> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.premiumHairline),
      ),
      child: Row(
        children: [
          for (final item in _PlanoMenu.values)
            Expanded(child: _item(context, item)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, _PlanoMenu item) {
    final ativo = item == selecionado;
    final cor = item.cor(primaria);
    return Material(
      color: ativo
          ? PlanoTipoMetalColors.badgeBackground(cor)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onSelecionar(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Text(
            item.titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              color: ativo ? cor : context.premiumTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VantagensPlano extends StatelessWidget {
  const _VantagensPlano({required this.menu, required this.primaria});

  final _PlanoMenu menu;
  final Color primaria;

  @override
  Widget build(BuildContext context) {
    final cor = menu.cor(primaria);
    final frases = menu.vantagens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            menu.titulo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < frases.length; i++) ...[
            Text(
              frases[i],
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: context.premiumTextPrimary,
              ),
            ),
            if (i < frases.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ProdutoLojaRow extends StatelessWidget {
  const _ProdutoLojaRow({
    required this.produto,
    required this.plano,
    required this.semPlanoPago,
    required this.ocupado,
    required this.onComprar,
  });

  final LojaProduto produto;
  final UserPlan plano;
  final bool semPlanoPago;
  final bool ocupado;
  final VoidCallback onComprar;

  PlanoTipo? get _tipoProduto {
    final id = produto.productId;
    if (id.endsWith('_bronze')) return PlanoTipo.bronze;
    if (id.endsWith('_prata')) return PlanoTipo.prata;
    if (id.endsWith('_ouro')) return PlanoTipo.ouro;
    return null;
  }

  bool get _isAtual =>
      !semPlanoPago &&
      !plano.expirado &&
      plano.ativo &&
      _tipoProduto != null &&
      _tipoProduto == plano.plano;

  bool get _mostrarPrecoCompra =>
      semPlanoPago ||
      (plano.expirado && _tipoProduto != null && _tipoProduto == plano.plano);

  @override
  Widget build(BuildContext context) {
    final tipo = _tipoProduto ?? PlanoTipo.bronze;
    final metal = PlanoTipoMetalColors.forTipo(tipo);

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
                        produto.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: metal,
                        ),
                      ),
                    ),
                    if (_isAtual)
                      Text(
                        'Atual',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.premiumTextSecondary,
                        ),
                      )
                    else
                      _LojaAcaoButton(
                        label: _mostrarPrecoCompra ? produto.preco : 'Mudar',
                        color: metal,
                        enabled: !ocupado,
                        onPressed: onComprar,
                      ),
                  ],
                ),
                Text(
                  '${produto.prazo} · pagamento único',
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
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  final String error;

  const _ErrorContent({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Erro ao carregar plano: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
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
        border: Border.all(color: context.premiumHairline),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.premiumTextPrimary,
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
        side: BorderSide(color: context.premiumHairline),
      ),
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
