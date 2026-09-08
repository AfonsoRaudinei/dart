import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';

/// Dropdown opcional de cliente para formulários de marketing.
/// Depende apenas de core/contracts/ — zero import de consultoria/ ou agenda/.
class MarketingClientSelector extends ConsumerWidget {
  static const _clearClientValue = '';

  final String? selectedClientId;
  final ValueChanged<ClientSummary?> onChanged;

  const MarketingClientSelector({
    super.key,
    required this.selectedClientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_marketingClientsAtivosProvider);
    final isIos = soloForteSheetIsIos(context);
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF2C2C2E);
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : const Color(0xFF3A3A3C);
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : const Color(0xFF8E8E93);
    final title =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final iconColor =
        isIos ? SoloForteSheetSkinIos.iconStroke : Colors.white70;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;
    final dropdownBg =
        isIos ? SoloForteSheetSkinIos.background : const Color(0xFF2C2C2E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: clientsAsync.when(
        loading: () => SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Carregando clientes…',
              style: TextStyle(color: muted),
            ),
          ),
        ),
        error: (_, __) => SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Erro ao carregar clientes',
              style: TextStyle(color: muted),
            ),
          ),
        ),
        data: (clients) {
          final hasSelected = selectedClientId != null &&
              clients.any((c) => c.id == selectedClientId);
          final value = hasSelected ? selectedClientId : null;

          return DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: value,
              dropdownColor: dropdownBg,
              iconEnabledColor: iconColor,
              hint: Text(
                'Selecionar cliente (opcional)',
                style: TextStyle(color: muted),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: _clearClientValue,
                  child: Text(
                    '—',
                    style: TextStyle(color: muted),
                  ),
                ),
                ...clients.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(
                      c.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: title),
                    ),
                  ),
                ),
              ],
              onChanged: (id) {
                if (id == null || id == _clearClientValue) {
                  onChanged(null);
                  return;
                }
                final client = clients.where((c) => c.id == id).firstOrNull;
                onChanged(client);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Provider interno — lista apenas ativos via IClientLookup de core/contracts/.
/// Não exportado — uso exclusivo de widgets em marketing/.
final _marketingClientsAtivosProvider =
    FutureProvider.autoDispose<List<ClientSummary>>(
  (ref) => ref.watch(clientLookupProvider).listAtivos(),
);
