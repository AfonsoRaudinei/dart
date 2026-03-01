import 'package:flutter/material.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/plano_marketing.dart';

class MarketingCaseMarker extends StatelessWidget {
  final MarketingCase marketingCase;
  final VoidCallback onTap;

  const MarketingCaseMarker({
    super.key,
    required this.marketingCase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos o tamanho de acordo com a regra de hierarquia AD-011
    double size = 48.0;
    String assetName = 'bronze.png';

    switch (marketingCase.visibilidade) {
      case PlanoMarketing.ouro:
        size = 80.0;
        assetName = 'ouro.png';
        break;
      case PlanoMarketing.prata:
        size = 64.0;
        assetName = 'prata.png';
        break;
      case PlanoMarketing.bronze:
        size = 48.0;
        assetName = 'bronze.png';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Semantics(
          label: 'Case de Marketing: ${marketingCase.produtoUtilizado}',
          button: true,
          child: Image.asset(
            'assets/images/pins/$assetName',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.location_on,
                color: marketingCase.visibilidade == PlanoMarketing.ouro
                    ? Colors.amber
                    : marketingCase.visibilidade == PlanoMarketing.prata
                    ? Colors.grey
                    : Colors.brown,
                size: size,
              );
            },
          ),
        ),
      ),
    );
  }
}
