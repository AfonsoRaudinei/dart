import 'package:flutter/material.dart';

import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../data/services/loja_compra_gateway.dart';
import '../domain/entities/user_plan.dart';
import '../domain/enums/plano_tipo.dart';
import '../domain/store_plan_catalog.dart';
import 'plano_tipo_metal_colors.dart';

enum MeuPlanoMenu {
  gratis,
  bronze,
  prata,
  ouro;

  static const _titulos = ['Grátis', 'Bronze', 'Prata', 'Ouro'];

  static MeuPlanoMenu doPlano(UserPlan plano) {
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

  String? get productIdLoja => switch (this) {
    gratis => null,
    bronze => 'soloforte_plano_bronze',
    prata => 'soloforte_plano_prata',
    ouro => 'soloforte_plano_ouro',
  };

  List<String> get vantagensBase => switch (this) {
    gratis => const [
      'Comece sem custo.',
      'Seu case fica salvo e visível só para você no mapa.',
      'Crie ocorrências sempre que precisar.',
      'Convide um vínculo para ver fazenda, talhões, mapa e desenhos.',
      'Compartilhar ocorrências e cases com o vínculo é exclusivo dos planos pagos.',
    ],
    bronze => const [
      'Dê os primeiros passos com visibilidade.',
      '5 cases no metal Bronze.',
      'Pin visível para você e seu vínculo a partir do zoom 14.',
      'Compartilhe ocorrências diretamente com seu vínculo.',
      'A cada 5 indicações, você sobe para o Prata.',
    ],
    prata => const [
      'Mais alcance para o seu trabalho.',
      '5 cases Bronze + 5 cases Prata.',
      'Pin visível para qualquer usuário logado, a partir do zoom 12.',
      'Compartilhe cases e ocorrências com seu vínculo.',
      'A cada 10 indicações, você sobe para o Ouro.',
    ],
    ouro => const [
      'Máxima visibilidade e precisão.',
      '5 cases Bronze, 5 Prata e 10 Ouro.',
      'Pin visível para todos, até sem login, a partir do zoom 8.',
      'Em caso de duplicidade com o produtor, seu pin aparece em destaque no mapa.',
      'NDVI com maior nível de detalhe.',
      'Compartilhe ocorrências com seu vínculo.',
    ],
  };
}

List<String> vantagensMenuPlano(MeuPlanoMenu menu, LojaVitrine vitrine) {
  final base = menu.vantagensBase;
  if (menu == MeuPlanoMenu.gratis) return base;

  final productId = menu.productIdLoja;
  if (productId == null) return base;

  LojaProduto? produto;
  for (final item in vitrine.produtos) {
    if (item.productId == productId) {
      produto = item;
      break;
    }
  }

  final offer = storePlanOfferFor(productId);
  final primeiraLinha = produto != null
      ? '${produto.preco} · ${produto.prazo} · pagamento único'
      : '${offer!.prazo} · preço na loja ao comprar';

  return [primeiraLinha, ...base];
}

class MeuPlanoMenuBar extends StatelessWidget {
  const MeuPlanoMenuBar({
    super.key,
    required this.selecionado,
    required this.primaria,
    required this.onSelecionar,
  });

  final MeuPlanoMenu selecionado;
  final Color primaria;
  final ValueChanged<MeuPlanoMenu> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.premiumCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isPremiumDark ? 0.28 : 0.05,
            ),
            offset: const Offset(0, 6),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in MeuPlanoMenu.values)
            Expanded(child: _item(context, item)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, MeuPlanoMenu item) {
    final ativo = item == selecionado;
    final cor = item.cor(primaria);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: ativo
            ? PlanoTipoMetalColors.badgeBackground(cor)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: ativo
            ? [
                BoxShadow(
                  color: cor.withValues(alpha: 0.28),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}

class MeuPlanoVantagensCard extends StatefulWidget {
  const MeuPlanoVantagensCard({
    super.key,
    required this.menu,
    required this.primaria,
    required this.vitrine,
  });

  final MeuPlanoMenu menu;
  final Color primaria;
  final LojaVitrine vitrine;

  @override
  State<MeuPlanoVantagensCard> createState() => _MeuPlanoVantagensCardState();
}

class _MeuPlanoVantagensCardState extends State<MeuPlanoVantagensCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant MeuPlanoVantagensCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu != widget.menu) _entrada.forward(from: 0);
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  double _progressoItem(int ordem, bool semMovimento) {
    if (semMovimento) return 1;
    final inicio = 0.12 + ordem * 0.09;
    final bruto = ((_entrada.value - inicio) / (1 - inicio)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(bruto);
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.menu.cor(widget.primaria);
    final frases = vantagensMenuPlano(widget.menu, widget.vitrine);
    final semMovimento = MediaQuery.disableAnimationsOf(context);
    final escuro = context.isPremiumDark;
    // Grátis: 1ª linha é a tagline. Pagos: 1ª é preço, 2ª é a tagline.
    final indiceTagline = widget.menu == MeuPlanoMenu.gratis ? 0 : 1;

    return AnimatedBuilder(
      animation: _entrada,
      builder: (context, _) {
        final t = semMovimento
            ? 1.0
            : Curves.easeOutCubic.transform(_entrada.value);
        return Opacity(
          opacity: 0.25 + 0.75 * t,
          child: Transform(
            alignment: const Alignment(0, -0.3),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX((1 - t) * -0.07)
              ..rotateY((1 - t) * 0.03),
            child: Container(
              key: const Key('meuPlanoVantagensCard'),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(context.premiumSurface, cor, 0.06)!,
                    context.premiumSurface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cor.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: escuro ? 0.22 : 0.16),
                    offset: const Offset(0, 14),
                    blurRadius: 28,
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: escuro ? 0.32 : 0.06),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SeloMetal3d(cor: cor),
                      const SizedBox(width: 12),
                      Text(
                        widget.menu.titulo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < frases.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    if (i == 0 && widget.menu != MeuPlanoMenu.gratis)
                      Text(
                        frases[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.premiumTextSecondary,
                        ),
                      )
                    else if (i == indiceTagline)
                      Text(
                        frases[i],
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: context.premiumTextPrimary,
                        ),
                      )
                    else
                      _VantagemBullet(
                        texto: frases[i],
                        cor: cor,
                        progresso: _progressoItem(
                          i - indiceTagline - 1,
                          semMovimento,
                        ),
                        textoCor: context.premiumTextPrimary,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Selo circular do metal com gradiente, brilho e sombra — efeito 3D leve.
class _SeloMetal3d extends StatelessWidget {
  const _SeloMetal3d({required this.cor});

  final Color cor;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(cor);
    final claro = hsl
        .withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0))
        .toColor();
    final sombra = hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
        .toColor();
    return ExcludeSemantics(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [claro, cor, sombra],
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.4),
              offset: const Offset(0, 5),
              blurRadius: 10,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                width: 12,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Benefício com bullet 3D (esfera com brilho + sombra) e entrada escalonada.
class _VantagemBullet extends StatelessWidget {
  const _VantagemBullet({
    required this.texto,
    required this.cor,
    required this.progresso,
    required this.textoCor,
  });

  final String texto;
  final Color cor;
  final double progresso;
  final Color textoCor;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(cor);
    final claro = hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .toColor();
    return Opacity(
      opacity: progresso,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - progresso)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                key: const Key('meuPlanoVantagemBullet'),
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.35),
                    colors: [claro, cor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.45),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(fontSize: 15, height: 1.35, color: textoCor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
