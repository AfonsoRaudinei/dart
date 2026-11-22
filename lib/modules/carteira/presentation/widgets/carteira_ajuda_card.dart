import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

/// Textos de ajuda de cada aba da Carteira.
///
/// Mantidos em um só lugar para o módulo explicar o próprio funcionamento
/// sem espalhar copy pelas telas.
class CarteiraAjudaTextos {
  CarteiraAjudaTextos._();

  static String resumo(CarteiraSegment segment) => switch (segment) {
    CarteiraSegment.clientes =>
      'Escolha um produtor para registrar o que ele já fechou com você.',
    CarteiraSegment.categorias =>
      'Categorias são os grupos de produto que você vende.',
    CarteiraSegment.metas =>
      'Defina quanto quer vender de cada categoria na safra ativa.',
    CarteiraSegment.oportunidades =>
      'Aqui está o que ainda falta fechar com cada produtor.',
  };

  static List<String> detalhes(CarteiraSegment segment) => switch (segment) {
    CarteiraSegment.clientes => const [
      'Toque no produtor para ver as categorias dele.',
      'Em cada categoria, o botão Lançamento registra quanto % do potencial '
          'daquele produtor você já vendeu.',
      'O que ainda não foi fechado vira oportunidade na aba Oportunidades.',
    ],
    CarteiraSegment.categorias => const [
      'Exemplos: Nutrição, Sementes de soja, Defensivos.',
      'Cada categoria tem uma unidade (R\$/ha, Big Bag, Sacas 60k, '
          'Sacas 500 mil sementes, R\$ total…) e um valor de referência.',
      'Só categorias em R\$/ha entram no total em reais das Oportunidades. '
          'R\$ total é para metas em valor fechado, como adjuvantes.',
      'Desativar esconde a categoria das telas. Os lançamentos já feitos '
          'ficam guardados.',
    ],
    CarteiraSegment.metas => const [
      'Só existe uma safra ativa por vez. Crie outra em Nova safra.',
      'A meta vale por categoria e safra, para a carteira toda — não é uma '
          'meta de cada produtor.',
      'O progresso vem dos lançamentos registrados na aba Clientes.',
      'O valor do grão mostra quanto uma categoria em R\$/ha equivale em '
          'sacas por hectare.',
    ],
    CarteiraSegment.oportunidades => const [
      'Oportunidade = o que falta fechar × área do produtor × valor de '
          'referência da categoria.',
      'O total em R\$ soma só categorias em R\$/ha. Sacas, Big Bag e ton/ha '
          'não entram nesse total: aparecem no produtor, na unidade delas.',
      'Toque em um produtor para ver o detalhe por categoria.',
    ],
  };
}

/// Card compacto "Como funciona": uma frase sempre visível e os detalhes
/// ao tocar.
class CarteiraAjudaCard extends StatefulWidget {
  const CarteiraAjudaCard({
    super.key,
    required this.segment,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final CarteiraSegment segment;

  /// Margem externa. Use [EdgeInsets.zero] horizontal quando a lista pai
  /// já tem padding lateral.
  final EdgeInsetsGeometry margin;

  @override
  State<CarteiraAjudaCard> createState() => _CarteiraAjudaCardState();
}

class _CarteiraAjudaCardState extends State<CarteiraAjudaCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final detalhes = CarteiraAjudaTextos.detalhes(widget.segment);

    return Semantics(
      container: true,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expandido = !_expandido),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(SFIcons.info, size: 18, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        CarteiraAjudaTextos.resumo(widget.segment),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.premiumTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        SFIcons.chevronDown,
                        size: 16,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                if (_expandido) ...[
                  const SizedBox(height: 8),
                  for (final linha in detalhes)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(
                            child: Text(
                              linha,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 4),
                    child: Text(
                      'Como funciona',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vazio com título e próximo passo.
class CarteiraEstadoVazio extends StatelessWidget {
  const CarteiraEstadoVazio({
    super.key,
    required this.titulo,
    required this.mensagem,
  });

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
