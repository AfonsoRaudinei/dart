import 'package:flutter/material.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/models/marketing_pin.dart';

class MarketingPinMarker extends StatelessWidget {
  final MarketingPin pin;
  final VoidCallback onTap;

  const MarketingPinMarker({super.key, required this.pin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. Definições por hierarquia de plano
    final config = _getPlanConfig(pin.plano);

    // 2. Montagem do Pin visual
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Borda arredondada do Pin e a imagem do Parceiro
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: config.size,
                height: config.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: config.borderColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    pin.imagemUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // Selo/Badgezinho de ROI (%)
              Positioned(
                bottom: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB), // Azul Forte
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '+${pin.roiPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Título do Produto no Pin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              pin.nomeProduto,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Definição de Cores e Tamanhos de acordo com a ADR-011
  _PlanConfig _getPlanConfig(PlanoMarketing plano) {
    switch (plano) {
      case PlanoMarketing.ouro:
        return _PlanConfig(size: 80, borderColor: const Color(0xFFFFB800));
      case PlanoMarketing.prata:
        return _PlanConfig(size: 64, borderColor: const Color(0xFFC0C0C0));
      case PlanoMarketing.bronze:
        return _PlanConfig(size: 48, borderColor: const Color(0xFFCD7F32));
    }
  }
}

class _PlanConfig {
  final double size;
  final Color borderColor;

  _PlanConfig({required this.size, required this.borderColor});
}
