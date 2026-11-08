part of 'drawing_sheet.dart';

class _SelectedModeFooter extends StatelessWidget {
  const _SelectedModeFooter({
    required this.safeBottom,
    required this.onExit,
    required this.onEdit,
  });

  final double safeBottom;
  final VoidCallback onExit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final footerBg = isIos
        ? v.sheetBackground
        : v.sheetBackground;
    final topBorder = v.cardBorder;

    return Container(
      key: const Key('drawing_selected_sticky_footer'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        safeBottom > 0 ? safeBottom : 16,
      ),
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(
          top: BorderSide(
            color: topBorder,
            width: PremiumTokens.hairlineThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('drawing_selected_edit_button'),
              onPressed: onEdit,
              style: isIos
                  ? OutlinedButton.styleFrom(
                      foregroundColor: v.ghostText,
                      side: BorderSide(
                        color: v.ghostBorder,
                      ),
                    )
                  : null,
              child: const Text('Editar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              key: const Key('drawing_selected_exit_button'),
              onPressed: onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isIos
                    ? v.ctaBackground
                    : context.themeAccent,
              ),
              child: const Text(
                'Sair da seleção',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const _SheetHeader({this.onBack, this.onClose});

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final titleColor = v.titleColor;
    final iconColor = isIos
        ? v.iconStroke
        : Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  key: const Key('drawing_sheet_back'),
                  tooltip: 'Voltar',
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: iconColor,
                  ),
                ),
              Expanded(
                child: Text(
                  'Ferramentas de Desenho',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: isIos ? 16 : 18,
                    fontWeight: isIos ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  key: const Key('drawing_sheet_close'),
                  tooltip: 'Fechar',
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: iconColor),
                ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isIos
              ? v.rowDivider
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

enum _ExportOption {
  geojson(
    DrawingExportFormat.geojson,
    'GeoJSON',
    'Padrão GIS moderno',
    Icons.map_outlined,
  ),
  gpx(
    DrawingExportFormat.gpx,
    'GPX',
    'Trilhas e pontos GPS',
    Icons.route_outlined,
  ),
  dxf(
    DrawingExportFormat.dxf,
    'DXF',
    'CAD/AutoCAD',
    Icons.architecture_outlined,
  ),
  csv(
    DrawingExportFormat.csv,
    'CSV',
    'Planilha com vértices',
    Icons.table_chart_outlined,
  ),
  txt(
    DrawingExportFormat.txt,
    'TXT',
    'Relatório textual',
    Icons.description_outlined,
  ),
  pdf(
    DrawingExportFormat.pdf,
    'PDF',
    'Coordenadas para operação',
    Icons.picture_as_pdf_outlined,
  );

  final DrawingExportFormat format;
  final String label;
  final String subtitle;
  final IconData icon;

  const _ExportOption(this.format, this.label, this.subtitle, this.icon);
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final valueColor = v.isIos ? v.titleColor : null;
    final labelColor = isIos
        ? v.subtitleColor
        : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final VoidCallback onTap;
  const _FormatButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.sublabel,
  });
  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final surface = isIos
        ? v.cardBackground
        : Colors.grey[50];
    final border = isIos ? v.cardBorder : Colors.grey[300]!;
    final iconColor = isIos
        ? v.iconStroke
        : Theme.of(context).primaryColor;
    final labelColor = v.isIos ? v.titleColor : null;
    final sublabelColor = isIos
        ? v.subtitleColor
        : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        v.cardRadius,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(
            v.cardRadius,
          ),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sublabel!,
                style: TextStyle(fontSize: 12, color: sublabelColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
