import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

class TipoProdutoFormResult {
  const TipoProdutoFormResult({
    required this.label,
    this.converteSacasHa = false,
  });

  final String label;
  final bool converteSacasHa;
}

/// Dialog compacto para cadastrar um novo tipo de produto / unidade.
class TipoProdutoFormDialog extends StatefulWidget {
  const TipoProdutoFormDialog({super.key});

  @override
  State<TipoProdutoFormDialog> createState() => _TipoProdutoFormDialogState();
}

class _TipoProdutoFormDialogState extends State<TipoProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  bool _converteSacasHa = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final color = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : Theme.of(context).colorScheme.primary;
    // Modal já pinta prata iOS — evitar segundo painel opaco (“dois sheets”).
    final sheetBg = isIos
        ? Colors.transparent
        : Theme.of(context).colorScheme.surface;
    final sheetRadius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : 24.0;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : Colors.grey.shade300;
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : null;
    final subColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : Colors.grey[600];
    final ctaBg = isIos ? SoloForteSheetSkinIos.ctaBackground : null;
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : null;
    final ctaRadius = isIos ? SoloForteSheetSkinIos.ctaRadius : 20.0;
    final ghostColor = isIos ? SoloForteSheetSkinIos.ghostText : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
          border: isIos
              ? const Border(
                  top: BorderSide(color: SoloForteSheetSkinIos.sheetBorder),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: isIos
                  ? SoloForteSheetSkinIos.handleSize.width
                  : 40,
              height: isIos
                  ? SoloForteSheetSkinIos.handleSize.height
                  : 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo tipo de produto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ex.: Litros/ha, Sc/ha, Doses/ha',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: subColor),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _labelController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        labelText: 'Unidade / tipo',
                        labelStyle: TextStyle(color: subColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: isIos
                              ? const BorderSide(
                                  color: SoloForteSheetSkinIos.cardBorder,
                                )
                              : const BorderSide(),
                        ),
                        enabledBorder: isIos
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: SoloForteSheetSkinIos.cardBorder,
                                ),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da unidade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _converteSacasHa,
                      activeThumbColor: color,
                      title: Text(
                        'Converte para sacas/ha',
                        style: TextStyle(color: titleColor),
                      ),
                      subtitle: Text(
                        'Ative para tipos baseados em R\$/ha',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subColor,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _converteSacasHa = value),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: ghostColor),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.of(context).pop(
                          TipoProdutoFormResult(
                            label: _labelController.text.trim(),
                            converteSacasHa: _converteSacasHa,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ctaBg,
                        foregroundColor: ctaFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ctaRadius),
                        ),
                      ),
                      child: const Text('Adicionar'),
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
}
