import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../../modules/consultoria/occurrences/domain/occurrence.dart';

class MapOccurrenceSheet extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Function(String category, String urgency, String description) onConfirm;
  final VoidCallback? onCancel;
  final ScrollController? scrollController;

  const MapOccurrenceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
    this.onCancel,
    this.scrollController,
  });

  @override
  State<MapOccurrenceSheet> createState() => _MapOccurrenceSheetState();
}

class _MapOccurrenceSheetState extends State<MapOccurrenceSheet> {
  OccurrenceCategory _selectedCategory = OccurrenceCategory.doenca;
  String _selectedUrgency = 'Média';
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: SoloForteColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SoloForteColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Nova Ocorrência',
                  style: SoloTextStyles.headingMedium,
                ),
              ),
            ),
            const Divider(height: 24, color: SoloForteColors.borderLight),

            // Content
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria
                    Text(
                      'Categoria',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OccurrenceCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SoloForteColors.greenIOS
                                  : SoloForteColors.grayLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? SoloForteColors.greenIOS
                                    : SoloForteColors.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : SoloForteColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Urgência
                    Text(
                      'Urgência',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Baixa', 'Média', 'Alta'].map((urgency) {
                        final isSelected = _selectedUrgency == urgency;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedUrgency = urgency),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SoloForteColors.greenIOS.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? SoloForteColors.greenIOS
                                      : SoloForteColors.borderLight,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? SoloForteColors.greenIOS
                                            : SoloForteColors.borderLight,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? SoloForteColors.greenIOS
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    urgency,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? SoloForteColors.greenIOS
                                          : SoloForteColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Descrição
                    Text(
                      'Descrição (opcional)',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLength: 280,
                      maxLines: 3,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descreva a ocorrência...',
                        hintStyle: TextStyle(
                          color: SoloForteColors.textTertiary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: SoloForteColors.grayLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: SoloTextStyles.label,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Coordenadas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: SoloForteColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                          style: SoloTextStyles.label.copyWith(
                            color: SoloForteColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onCancel?.call();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: SoloForteColors.borderLight,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: SoloTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: SoloForteColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onConfirm(
                            _selectedCategory.name,
                            _selectedUrgency,
                            _descriptionController.text,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SoloForteColors.greenIOS,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirmar',
                          style: SoloTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get selectedCategoryName => _selectedCategory.name;
  String get selectedUrgency => _selectedUrgency;
  String get description => _descriptionController.text;
}
