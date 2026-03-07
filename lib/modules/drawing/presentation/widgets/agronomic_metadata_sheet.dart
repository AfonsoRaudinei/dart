import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/drawing_models.dart';
import '../controllers/drawing_controller.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

// =============================================================================
// CONSTANTES DO DOMÍNIO
// =============================================================================

const List<String> _kCulturas = [
  'Soja',
  'Milho',
  'Café',
  'Algodão',
  'Trigo',
  'Cana-de-açúcar',
  'Sorgo',
  'Feijão',
  'Arroz',
  'Pastagem',
  'Outro',
];

const List<String> _kSamplingSchemes = ['grade', 'zona', 'dirigido'];

const List<String> _kNutrientes = ['N', 'P', 'K', 'S', 'Ca', 'Mg', 'B', 'Zn'];

// =============================================================================
// WIDGET PRINCIPAL
// =============================================================================

/// Bottom sheet iOS Premium para edição de campos agronômicos de um talhão.
///
/// Campos editáveis:
/// - Nome
/// - Cultura (soja, milho, café …)
/// - Safra (ex: 2025/2026)
/// - Esquema de amostragem de solo (grade | zona | dirigido)
/// - Recomendações por nutriente (N, P, K, S, Ca, Mg …)
///
/// Ao salvar, chama [DrawingController.updateMetadata] e fecha a sheet.
class AgronomicMetadataSheet extends StatefulWidget {
  final DrawingFeature feature;
  final DrawingController controller;

  const AgronomicMetadataSheet({
    super.key,
    required this.feature,
    required this.controller,
  });

  @override
  State<AgronomicMetadataSheet> createState() => _AgronomicMetadataSheetState();
}

class _AgronomicMetadataSheetState extends State<AgronomicMetadataSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _safraCtrl;

  String? _cultura;
  String? _samplingScheme;

  // Mapa de controladores de texto por nutriente
  late final Map<String, TextEditingController> _nutriCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.feature.properties;

    _nomeCtrl = TextEditingController(text: p.nome);
    _safraCtrl = TextEditingController(text: p.safra ?? '');
    _cultura = p.cultura;
    _samplingScheme = p.soilSamplingScheme;

    _nutriCtrl = {
      for (final n in _kNutrientes)
        n: TextEditingController(
          text: p.recByNutrient?[n]?.toStringAsFixed(1) ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _safraCtrl.dispose();
    for (final c in _nutriCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SALVAR
  // ---------------------------------------------------------------------------

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    // Monta mapa de nutrientes — ignora campos vazios
    final Map<String, double> nutr = {};
    for (final entry in _nutriCtrl.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value != null) nutr[entry.key] = value;
    }

    widget.controller.updateMetadata(
      widget.feature.id,
      nome: _nomeCtrl.text.trim(),
      cultura: _cultura,
      safra: _safraCtrl.text.trim().isEmpty ? null : _safraCtrl.text.trim(),
      soilSamplingScheme: _samplingScheme,
      recByNutrient: nutr.isEmpty ? null : nutr,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informações agronômicas salvas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                offset: Offset(0, -4),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag pill ───────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFC5C5C7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              // ── Título ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Informações Agronômicas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: PremiumTokens.brandGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // ── Corpo ────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Seção: Identificação ─────────────────────
                        const _SectionHeader(label: 'Identificação'),
                        const SizedBox(height: 8),
                        _PremiumTextField(
                          controller: _nomeCtrl,
                          label: 'Nome do talhão',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Nome obrigatório'
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // ── Seção: Cultura e Safra ───────────────────
                        const _SectionHeader(label: 'Cultura e Safra'),
                        const SizedBox(height: 8),
                        _CulturaDropdown(
                          value: _cultura,
                          onChanged: (v) => setState(() => _cultura = v),
                        ),
                        const SizedBox(height: 12),
                        _PremiumTextField(
                          controller: _safraCtrl,
                          label: 'Safra',
                          hint: '2025/2026',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 20),

                        // ── Seção: Amostragem de Solo ────────────────
                        const _SectionHeader(label: 'Amostragem de Solo'),
                        const SizedBox(height: 8),
                        _SamplingChips(
                          selected: _samplingScheme,
                          onSelected: (v) =>
                              setState(() => _samplingScheme = v),
                        ),
                        const SizedBox(height: 20),

                        // ── Seção: Recomendação de Adubação ─────────
                        const _SectionHeader(label: 'Recomendação de Adubação (kg/ha)'),
                        const SizedBox(height: 8),
                        _NutrientGrid(controllers: _nutriCtrl),
                        const SizedBox(height: 28),

                        // ── Botão Salvar ──────────────────────────────
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PremiumTokens.brandGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Salvar informações',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTES INTERNOS
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF8E8E93),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          color: Color(0xFF000000),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CulturaDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CulturaDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text(
            'Selecionar cultura',
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
          isExpanded: true,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Nenhuma',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
            ..._kCulturas.map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SamplingChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SamplingChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _kSamplingSchemes.map((scheme) {
        final isActive = selected == scheme;
        return ChoiceChip(
          label: Text(
            scheme,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF3C3C43),
            ),
          ),
          selected: isActive,
          selectedColor: PremiumTokens.brandGreen,
          backgroundColor: const Color(0xFFF2F2F7),
          side: BorderSide.none,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            onSelected(isActive ? null : scheme);
          },
        );
      }).toList(),
    );
  }
}

class _NutrientGrid extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const _NutrientGrid({required this.controllers});

  @override
  Widget build(BuildContext context) {
    final entries = controllers.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              TextField(
                controller: entry.value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '—',
                  hintStyle: TextStyle(
                    color: Color(0xFFC7C7CC),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
