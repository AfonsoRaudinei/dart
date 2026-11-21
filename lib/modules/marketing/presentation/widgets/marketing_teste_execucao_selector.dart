import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import '../../../../core/contracts/i_teste_execucao_lookup.dart';
import '../../../../core/contracts/i_teste_execucao_lookup_provider.dart';

class MarketingTesteExecucaoSelector extends ConsumerWidget {
  const MarketingTesteExecucaoSelector({
    super.key,
    required this.clientId,
    this.farmId,
    this.selectedExecucaoId,
    required this.onSelected,
    required this.onCleared,
  });

  final String? clientId;
  final String? farmId;
  final String? selectedExecucaoId;
  final ValueChanged<TesteExecucaoOption> onSelected;
  final VoidCallback onCleared;

  static const _clearValue = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = SoloForteSheetVisuals.of(context);
    final muted = v.subtitleColor;
    final title = v.titleColor;
    final border = v.cardBorder;
    final surface = v.cardBackground;
    final radius = v.cardRadius;

    final cid = clientId?.trim() ?? '';
    if (cid.isEmpty) {
      return Text(
        'Selecione um cliente para listar testes executados.',
        style: TextStyle(fontSize: 13.5, color: muted),
      );
    }

    return FutureBuilder<List<TesteExecucaoOption>>(
      future: ref
          .read(iTesteExecucaoLookupProvider)
          .listByClient(clientId: cid, farmId: farmId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Carregando testes…', style: TextStyle(color: muted));
        }
        if (snapshot.hasError) {
          return Text(
            'Não foi possível carregar os testes.',
            style: TextStyle(color: muted),
          );
        }

        final options = snapshot.data ?? const [];
        final hasSelected = selectedExecucaoId != null &&
            options.any((o) => o.id == selectedExecucaoId);
        final value = hasSelected ? selectedExecucaoId : null;

        if (options.isEmpty) {
          return Text(
            'Nenhuma execução de teste para este cliente.',
            style: TextStyle(fontSize: 13.5, color: muted),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: value,
              dropdownColor: v.sheetBackground,
              hint: Text(
                'Teste vinculado (opcional)',
                style: TextStyle(color: muted),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: _clearValue,
                  child: Text('—', style: TextStyle(color: muted)),
                ),
                ...options.map(
                  (o) => DropdownMenuItem<String?>(
                    value: o.id,
                    child: Text(
                      o.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: title),
                    ),
                  ),
                ),
              ],
              onChanged: (id) {
                if (id == null || id == _clearValue) {
                  onCleared();
                  return;
                }
                final match = options.where((o) => o.id == id).firstOrNull;
                if (match != null) onSelected(match);
              },
            ),
          ),
        );
      },
    );
  }
}