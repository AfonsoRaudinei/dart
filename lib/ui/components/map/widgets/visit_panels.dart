import 'package:flutter/material.dart';

import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'media/photo_grid.dart';

// ════════════════════════════════════════════════════════════════════
// BASE PANEL WIDGETS
// ════════════════════════════════════════════════════════════════════

class PanelSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double max;
  final int divisions;
  final String? suffix;

  const PanelSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 100,
    this.divisions = 100,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${value.toInt()}${suffix ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: SoloForteColors.textSecondary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: SoloForteColors.greenIOS,
            inactiveTrackColor: SoloForteColors.greenIOS.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            overlayColor: SoloForteColors.greenIOS.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 2,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class PanelTextField extends StatelessWidget {
  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const PanelTextField({
    super.key,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: SoloForteColors.grayLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// CATEGORY SPECIFIC PANELS
// ════════════════════════════════════════════════════════════════════

// ... (PanelSlider and PanelTextField remain unchanged)

// ════════════════════════════════════════════════════════════════════
// CATEGORY SPECIFIC PANELS
// ════════════════════════════════════════════════════════════════════

class DoencaPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const DoencaPanel({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelSlider(
          label: 'Severidade (%)',
          value: (data['severidade'] as num?)?.toDouble() ?? 0,
          onChanged: (v) => onUpdate({...data, 'severidade': v}),
          suffix: '%',
        ),
        const SizedBox(height: 12),
        PanelTextField(
          hint: 'Observações sobre a doença...',
          initialValue: data['obs'] as String? ?? '',
          onChanged: (v) => onUpdate({...data, 'obs': v}),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          categoryId: 'doenca',
          photos: photos,
          onAdd: onAddPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class PragaPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const PragaPanel({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelSlider(
          label: 'Desfolha (%)',
          value: (data['desfolha'] as num?)?.toDouble() ?? 0,
          onChanged: (v) => onUpdate({...data, 'desfolha': v}),
          suffix: '%',
        ),
        const SizedBox(height: 8),
        PanelSlider(
          label: 'População (0-100)',
          value: (data['populacao'] as num?)?.toDouble() ?? 0,
          onChanged: (v) => onUpdate({...data, 'populacao': v}),
        ),
        const SizedBox(height: 12),
        PanelTextField(
          hint: 'Observações sobre a praga...',
          initialValue: data['obs'] as String? ?? '',
          onChanged: (v) => onUpdate({...data, 'obs': v}),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          categoryId: 'insetos',
          photos: photos,
          onAdd: onAddPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class DaninhaPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const DaninhaPanel({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelSlider(
          label: 'Infestação (%)',
          value: (data['infestacao'] as num?)?.toDouble() ?? 0,
          onChanged: (v) => onUpdate({...data, 'infestacao': v}),
          suffix: '%',
        ),
        const SizedBox(height: 12),
        PanelTextField(
          hint: 'Observações sobre daninhas...',
          initialValue: data['obs'] as String? ?? '',
          onChanged: (v) => onUpdate({...data, 'obs': v}),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          categoryId: 'ervas',
          photos: photos,
          onAdd: onAddPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class FisiologicoPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const FisiologicoPanel({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final tipos = [
      'Hídrico (Seca)',
      'Hídrico (Excesso)',
      'Térmico (Calor)',
      'Térmico (Geada)',
      'Fitotoxidez',
      'Outros',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(data['tipo'] as String?),
          isExpanded: true,
          initialValue: data['tipo'] as String?,
          decoration: InputDecoration(
            filled: true,
            fillColor: SoloForteColors.grayLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text('Selecione o tipo de estresse'),
          items: tipos
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => onUpdate({...data, 'tipo': v}),
        ),
        const SizedBox(height: 12),
        PanelTextField(
          hint: 'Observações fisiológicas...',
          initialValue: data['obs'] as String? ?? '',
          onChanged: (v) => onUpdate({...data, 'obs': v}),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          categoryId: 'fisiologico',
          photos: photos,
          onAdd: onAddPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class NutricaoPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const NutricaoPanel({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  static const elements = [
    'N',
    'P',
    'K',
    'Ca',
    'Mg',
    'S',
    'B',
    'Zn',
    'Fe',
    'Mn',
    'Cu',
    'Mo',
  ];

  @override
  Widget build(BuildContext context) {
    final elementosData = Map<String, String>.from(
      data['elementos'] as Map? ?? {},
    );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 300 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: elements.length,
              itemBuilder: (context, index) {
                final elem = elements[index];
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SoloForteColors.grayLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SoloForteColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        elem,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: TextFormField(
                          initialValue: elementosData[elem] ?? '',
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '-',
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            elementosData[elem] = v;
                            onUpdate({...data, 'elementos': elementosData});
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        PanelTextField(
          hint: 'Observações nutricionais...',
          initialValue: data['obs'] as String? ?? '',
          onChanged: (v) => onUpdate({...data, 'obs': v}),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          categoryId: 'nutrientes',
          photos: photos,
          onAdd: onAddPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class CategoryDetailPanel extends StatelessWidget {
  final String categoryId;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onRemove;
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  const CategoryDetailPanel({
    super.key,
    required this.categoryId,
    required this.data,
    required this.onUpdate,
    required this.onRemove,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    String title;
    Color headerColor;

    switch (categoryId) {
      case 'doenca':
        title = 'Doenças';
        headerColor = SoloForteColors.warning;
        content = DoencaPanel(
          data: data,
          onUpdate: onUpdate,
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        );
        break;
      case 'insetos':
        title = 'Pragas';
        headerColor = Colors.redAccent;
        content = PragaPanel(
          data: data,
          onUpdate: onUpdate,
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        );
        break;
      case 'ervas':
        title = 'Plantas Daninhas';
        headerColor = Colors.green;
        content = DaninhaPanel(
          data: data,
          onUpdate: onUpdate,
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        );
        break;
      case 'fisiologico':
      case 'agua':
        title = 'Fisiológico / Hídrico';
        headerColor = Colors.blue;
        content = FisiologicoPanel(
          data: data,
          onUpdate: onUpdate,
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        );
        break;
      case 'nutrientes':
        title = 'Nutrição';
        headerColor = Colors.purple;
        content = NutricaoPanel(
          data: data,
          onUpdate: onUpdate,
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        );
        break;
      default:
        title = 'Outros';
        headerColor = Colors.grey;
        content = Column(
          children: [
            PanelTextField(
              hint: 'Observações...',
              initialValue: data['obs'] as String? ?? '',
              onChanged: (v) => onUpdate({...data, 'obs': v}),
            ),
            const SizedBox(height: 16),
            PhotoGrid(
              categoryId: categoryId,
              photos: photos,
              onAdd: onAddPhoto,
              onRemove: onRemovePhoto,
            ),
          ],
        );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SoloForteColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: headerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: headerColor.withValues(alpha: 0.8), // Darker text
                    ),
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: SoloForteColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Panel Content
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }
}
