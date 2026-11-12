// ADR-012 Adendo 2 — planos/presentation/screens/planos_screen.dart
//
// Rota: /planos — preço e compra só quando a loja devolve o produto.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../data/services/loja_compra_gateway.dart';
import '../providers/plano_providers.dart';

class PlanosScreen extends ConsumerStatefulWidget {
  const PlanosScreen({super.key});

  @override
  ConsumerState<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends ConsumerState<PlanosScreen> {
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
    _carregar();
  }

  Future<void> _carregar() async {
    final vitrine = await ref.read(lojaCompraGatewayProvider).carregar();
    if (!mounted) return;
    setState(() => _vitrine = vitrine);
  }

  @override
  void dispose() {
    _avisos?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vitrine = _vitrine;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: context.premiumBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Planos SoloForte',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.premiumTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, kFabSafeArea),
        children: [
          Icon(Icons.workspace_premium_rounded, size: 64, color: primary),
          const SizedBox(height: 24),
          Text(
            'Status da assinatura',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          const _PlanoAtual(),
          const SizedBox(height: 24),
          if (vitrine == null)
            const Center(child: CircularProgressIndicator())
          else if (vitrine.produtos.isEmpty)
            Text(
              'A loja não tem planos disponíveis para compra neste momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: context.premiumTextSecondary),
            )
          else
            for (final produto in vitrine.produtos) ...[
              _ProdutoLoja(
                produto: produto,
                ocupado: _ocupado,
                onComprar: () => _comprar(produto.productId),
              ),
              const SizedBox(height: 12),
            ],
          if (_aviso != null) ...[
            const SizedBox(height: 12),
            Text(
              _aviso!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.premiumTextSecondary),
            ),
          ],
          if (vitrine != null && vitrine.disponivel) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _ocupado
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      ref.read(lojaCompraGatewayProvider).restaurar();
                    },
              child: Text('Restaurar compras', style: TextStyle(color: primary)),
            ),
          ],
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.map);
            },
            child: Text('Voltar ao mapa', style: TextStyle(fontSize: 15, color: primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _comprar(String productId) async {
    setState(() => _ocupado = true);
    try {
      await ref.read(lojaCompraGatewayProvider).comprar(productId);
    } catch (_) {
      if (mounted) {
        setState(() => _aviso = 'A loja não iniciou a compra.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }
}

class _PlanoAtual extends ConsumerWidget {
  const _PlanoAtual();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plano = ref.watch(planoAtivoProvider).valueOrNull;
    if (plano == null || !plano.ativo || plano.isIndefinite) {
      return const SizedBox.shrink();
    }
    final nome = plano.plano.name[0].toUpperCase() + plano.plano.name.substring(1);
    return Text(
      'Plano atual: $nome · ${plano.diasRestantesLabel} · '
      '${plano.limiteCases >= 999999 ? 'cases ilimitados no mapa' : 'até ${plano.limiteCases} cases no mapa'}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: context.premiumTextSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ProdutoLoja extends StatelessWidget {
  const _ProdutoLoja({
    required this.produto,
    required this.ocupado,
    required this.onComprar,
  });

  final LojaProduto produto;
  final bool ocupado;
  final VoidCallback onComprar;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.premiumTextPrimary,
                    ),
                  ),
                  Text(
                    '${produto.prazo} · ${produto.preco}',
                    style: TextStyle(fontSize: 14, color: context.premiumTextSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: ocupado
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onComprar();
                    },
              child: Text('Comprar', style: TextStyle(color: primary)),
            ),
          ],
        ),
      ),
    );
  }
}
