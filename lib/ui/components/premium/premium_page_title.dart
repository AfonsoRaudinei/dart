import 'package:flutter/material.dart';

import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Estilo único de título das telas principais (iOS "large title" compacto).
///
/// Todas as telas de seção (Agenda, Clientes, Relatórios, Carteira, Feedback,
/// Configurações, Meu Plano) usam este estilo: alinhado à esquerda, 28 pt,
/// negrito. Evita títulos de tamanhos e alinhamentos diferentes entre telas.
TextStyle premiumPageTitleStyle(BuildContext context) => TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.3,
  height: 1.15,
  color: context.premiumTextPrimary,
);

/// Título de página padrão, com o recuo horizontal de 16 usado nos conteúdos.
class PremiumPageTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const PremiumPageTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: premiumPageTitleStyle(context)),
      ),
    );
  }
}
