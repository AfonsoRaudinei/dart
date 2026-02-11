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
          topLeft: Radius.circular(24), // Premium Rounding
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: SoloForteColors.border,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header - Clean & Bold
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Nova Ocorrência',
                style: SoloTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Location Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SoloForteColors.grayLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: SoloForteColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                    style: SoloTextStyles.label.copyWith(
                      color: SoloForteColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Categoria
                    Text(
                      'O que você encontrou?',
                      style: SoloTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SoloForteColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: OccurrenceCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SoloForteColors.greenIOS
                                  : SoloForteColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? SoloForteColors.greenIOS
                                    : SoloForteColors.border,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: SoloForteColors.greenIOS
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : SoloForteColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Section: Urgência
                    Text(
                      'Nível de Urgência',
                      style: SoloTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SoloForteColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: SoloForteColors.grayLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['Baixa', 'Média', 'Alta'].map((urgency) {
                          final isSelected = _selectedUrgency == urgency;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedUrgency = urgency),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [SoloShadows.shadowSm]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    urgency,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? SoloForteColors.textPrimary
                                          : SoloForteColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section: Descrição
                    Text(
                      'Observações',
                      style: SoloTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SoloForteColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLength: 280,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Adicione detalhes sobre a ocorrência...',
                        hintStyle: TextStyle(
                          color: SoloForteColors.textTertiary,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: SoloForteColors.grayLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: SoloForteColors.greenIOS,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: SoloTextStyles.label,
                      ),
                      style: SoloTextStyles.body.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Actions - Premium Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: SoloForteColors.grayLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: () {
                          widget.onCancel?.call();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: SoloForteColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
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
                          shadowColor: SoloForteColors.greenIOS.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Confirmar',
                          style: SoloTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16,
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
