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
        border: Border.all(color: context.premiumHairline),
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

class MeuPlanoVantagensCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cor = menu.cor(primaria);
    final frases = vantagensMenuPlano(menu, vitrine);

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