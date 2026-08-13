import 'package:flutter/material.dart';

import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/enums/plano_marketing.dart';

/// Cor e ícone de cada tier, em um lugar só.
///
/// Antes o mesmo tier tinha cores diferentes no pin do mapa
/// (`0xFFFFD700`), no sheet e no seletor (`0xFFFFB800`), então o card
/// aberto não parecia o pin que o abriu. Os valores oficiais são os
/// tokens de tier, que o módulo planos já usa.
extension PlanoMarketingVisual on PlanoMarketing {
  Color get color => switch (this) {
    PlanoMarketing.ouro => PremiumTokens.tierGold,
    PlanoMarketing.prata => PremiumTokens.tierSilver,
    PlanoMarketing.bronze => PremiumTokens.tierBronze,
  };

  IconData get icon => switch (this) {
    PlanoMarketing.ouro => Icons.workspace_premium_rounded,
    PlanoMarketing.prata => Icons.verified_rounded,
    PlanoMarketing.bronze => Icons.star_border_rounded,
  };
}
