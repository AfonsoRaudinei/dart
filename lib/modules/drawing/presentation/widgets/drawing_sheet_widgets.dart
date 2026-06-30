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
    return Container(
      key: const Key('drawing_selected_sticky_footer'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        safeBottom > 0 ? safeBottom : 16,
      ),
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        border: Border(
          top: BorderSide(
            color: SoloForteSheetTokens.inputBackground,
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
              child: const Text('Editar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              key: const Key('drawing_selected_exit_button'),
              onPressed: onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTokens.brandGreen,
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
    final scheme = Theme.of(context).colorScheme;
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              const Expanded(
                child: Text(
                  'Ferramentas de Desenho',
                  style: TextStyle(
                    color: SoloForteSheetTokens.titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  key: const Key('drawing_sheet_close'),
                  tooltip: 'Fechar',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sublabel!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BigMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: PremiumTokens.textSecondaryLight, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final Color selected;
  final ValueChanged<Color> onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = color.toARGB32() == selected.toARGB32();
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              )
            : null,
      ),
    );
  }
}
