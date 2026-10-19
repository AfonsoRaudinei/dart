part of 'relatorios_page.dart';

/// Ícone circular no estilo das categorias de ocorrência / pins de marketing.
Widget _relatoriosReportIconBadge({
  required IconData icon,
  Color accent = const Color(0xFF2C5564),
  double size = 48,
}) {
  final ring = accent.withValues(alpha: 0.35);
  final fill = accent.withValues(alpha: 0.08);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill,
      border: Border.all(color: ring, width: 1.5),
    ),
    child: Icon(icon, size: size * 0.46, color: accent),
  );
}

IconData _relatoriosOccurrenceCategoryIcon(String? category) {
  switch (OccurrenceCategory.fromString(category)) {
    case OccurrenceCategory.doenca:
      return SFIcons.coronavirus;
    case OccurrenceCategory.insetos:
      return SFIcons.bugReport;
    case OccurrenceCategory.daninhas:
      return SFIcons.grass;
    case OccurrenceCategory.nutricional:
      return SFIcons.science;
    case OccurrenceCategory.agua:
      return SFIcons.waterDrop;
    case OccurrenceCategory.amostraSolo:
      return Icons.biotech_outlined;
    case OccurrenceCategory.areaVisitada:
      return SFIcons.pin;
  }
}

Color _relatoriosOccurrenceCategoryColor(String? category) {
  return OccurrenceCategory.fromString(category).markerColor;
}

IconData _relatoriosMarketingTipoIcon(String tipo) {
  switch (tipo) {
    case 'antes_depois':
      return SFIcons.compareArrows;
    case 'avaliacao':
      return SFIcons.starOutline;
    case 'resultado':
    default:
      return SFIcons.trendingUp;
  }
}

Color _relatoriosMarketingTipoColor(String tipo) {
  switch (tipo) {
    case 'antes_depois':
      return const Color(0xFF9C27B0);
    case 'avaliacao':
      return const Color(0xFF007AFF);
    case 'resultado':
    default:
      return const Color(0xFFFF9800);
  }
}

String _relatoriosMarketingTipoSectionTitle(String tipo) {
  switch (tipo) {
    case 'antes_depois':
      return 'Lado a lado';
    case 'avaliacao':
      return 'Avaliação';
    case 'resultado':
    default:
      return 'Resultado';
  }
}

class _RelatoriosSectionLabel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int? count;

  const _RelatoriosSectionLabel({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          _relatoriosReportIconBadge(
            icon: icon,
            accent: iconColor,
            size: 36,
          ),
          const SizedBox(width: 10),
          Text(
            count == null ? title : '$title · $count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.premiumTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
