import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:uuid/uuid.dart';

import '../../domain/client_cultura.dart';
import '../../domain/enums/cultura_tipo.dart';

/// Item de lista para exibição (e opcionalmente remoção) de uma [ClientCultura].
///
/// Quando [onRemove] é null, opera em modo somente-leitura.
class CulturaItemWidget extends StatelessWidget {
  final ClientCultura cultura;
  final VoidCallback? onRemove;

  const CulturaItemWidget({
    super.key,
    required this.cultura,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final areaFormatted =
        cultura.areaHa % 1 == 0
            ? '${cultura.areaHa.toStringAsFixed(0)} ha'
            : '${cultura.areaHa.toStringAsFixed(1)} ha';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              cultura.culturaTipo.label,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              areaFormatted,
              style: tt.labelSmall?.copyWith(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: cultura.variedadesList.isNotEmpty
          ? Text(
              ClientCultura.formatVariedades(cultura.variedade),
              style: tt.bodySmall?.copyWith(color: Colors.grey[600]),
            )
          : null,
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              onPressed: onRemove,
              tooltip: 'Remover cultura',
            )
          : null,
    );
  }
}

/// Campo de texto livre + chips para múltiplas variedades/cultivares.
class VariedadesCultivaresInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> variedades;
  final InputDecoration decoration;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const VariedadesCultivaresInput({
    super.key,
    required this.controller,
    required this.variedades,
    required this.decoration,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: decoration,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            IconButton(
              tooltip: 'Adicionar variedade',
              icon: const Icon(Icons.add_circle_outline),
              color: PremiumTokens.brandGreen,
              onPressed: onAdd,
            ),
          ],
        ),
        if (variedades.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: variedades
                .map(
                  (v) => InputChip(
                    label: Text(v),
                    onDeleted: () => onRemove(v),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet compartilhado para adicionar cultura (cadastro e edição).
Future<ClientCultura?> showAddCulturaSheet({
  required BuildContext context,
  required String clientId,
  required InputDecoration Function(String label) inputDecoration,
  String safraLabel = 'Safra',
}) async {
  final formKey = GlobalKey<FormState>();
  CulturaTipo? culturaSel;
  final areaCtrl = TextEditingController();
  final variedadeCtrl = TextEditingController();
  final safraCtrl = TextEditingController();
  final obsCtrl = TextEditingController();
  final variedades = <String>[];

  ClientCultura? result;

  await showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: false,
    builder: (ctx) {
      final ios = soloForteSheetIsIos(ctx);
      final titleColor = ios ? SoloForteSheetSkinIos.titleColor : null;
      final ctaBg = ios
          ? SoloForteSheetSkinIos.ctaBackground
          : PremiumTokens.brandGreen;
      final ctaFg = ios ? SoloForteSheetSkinIos.ctaText : Colors.white;
      final ctaRadius = ios ? SoloForteSheetSkinIos.ctaRadius : 8.0;

      void addVariedade(StateSetter setS) {
        final text = variedadeCtrl.text.trim();
        if (text.isEmpty || variedades.contains(text)) {
          variedadeCtrl.clear();
          return;
        }
        setS(() {
          variedades.add(text);
          variedadeCtrl.clear();
        });
      }

      return StatefulBuilder(
        builder: (ctx, setS) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: ctaBg),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Adicionar Cultura',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CulturaTipo>(
                      decoration: inputDecoration('Cultura *'),
                      items: CulturaTipo.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => culturaSel = v),
                      validator: (v) =>
                          v == null ? 'Selecione uma cultura' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: inputDecoration('Área (ha) *'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d <= 0) return 'Informe área > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    VariedadesCultivaresInput(
                      controller: variedadeCtrl,
                      variedades: variedades,
                      decoration: inputDecoration('Variedades / Cultivares')
                          .copyWith(hintText: 'BRS 284, M 6410…'),
                      onAdd: () => addVariedade(setS),
                      onRemove: (v) => setS(() => variedades.remove(v)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: safraCtrl,
                      decoration: inputDecoration(safraLabel),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: obsCtrl,
                      decoration: inputDecoration('Observação'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ctaBg,
                          foregroundColor: ctaFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ctaRadius),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) return;
                          result = ClientCultura(
                            id: const Uuid().v4(),
                            clientId: clientId,
                            cultura: culturaSel!.name,
                            areaHa: double.parse(areaCtrl.text),
                            variedade: ClientCultura.joinVariedades(variedades),
                            safra: safraCtrl.text.isEmpty
                                ? null
                                : safraCtrl.text,
                            observacao: obsCtrl.text.isEmpty
                                ? null
                                : obsCtrl.text,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Confirmar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  return result;
}
