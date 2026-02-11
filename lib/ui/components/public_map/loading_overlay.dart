import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

/// Skeleton loader para pins de publicações no mapa público.
///
/// Exibe placeholders pulsantes enquanto as publicações
/// estão sendo carregadas.
class PublicationsLoadingOverlay extends StatelessWidget {
  const PublicationsLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(SoloSpacing.md),
          decoration: BoxDecoration(
            color: SoloForteColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SoloForteColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: SoloSpacing.md),
              Text(
                'Carregando publicações...',
                style: SoloTextStyles.body.copyWith(
                  color: SoloForteColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader individual para pin no mapa.
///
/// Usado durante o carregamento inicial de publicações.
class PinSkeleton extends StatefulWidget {
  const PinSkeleton({super.key});

  @override
  State<PinSkeleton> createState() => _PinSkeletonState();
}

class _PinSkeletonState extends State<PinSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: SoloForteColors.grayLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: SoloForteColors.borderLight,
            width: 3,
          ),
        ),
      ),
    );
  }
}
