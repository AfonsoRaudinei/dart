import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/marketing_case.dart';

/// CTA do sheet de detalhe → abre `/marketing/story`.
class MarketingCaseStoryEntryButton extends StatelessWidget {
  final MarketingCase marketingCase;

  const MarketingCaseStoryEntryButton({
    required this.marketingCase,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        final caseData = marketingCase;
        final router = GoRouter.of(context);
        Navigator.of(context).pop(); // fecha sheet (modal — permitido)
        router.go(AppRoutes.marketingStory, extra: caseData);
      },
      icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 20),
      label: const Text('Ver Story / Compartilhar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5B935),
        foregroundColor: const Color(0xFF1D1D1F),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
