import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_city_selection_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Função de exibição ───────────────────────────────────────────────────────

/// Abre o painel de configurações do módulo Clima via modal bottom sheet.
void showClimaSettings(BuildContext context) {
  showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    maxHeightFraction: 0.55,
    builder: (_) => const ClimaSettingsSheet(),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class ClimaSettingsSheet extends ConsumerWidget {
  const ClimaSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unidade = ref.watch(climaUnidadeProvider);
    final selectedCity = ref.watch(climaSelectedCityProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: SoloForteSheetTokens.titleFontSize,
              fontWeight: SoloForteSheetTokens.titleWeight,
              color: SoloForteSheetTokens.titleColor,
            ),
          ),
          const SizedBox(height: 20),
          const _ClimaSheetSectionLabel('LOCALIZAÇÃO'),
          const SizedBox(height: 8),
          _ClimaSheetOptionGroup(
            children: [
              ClimaSettingsOptionRow(
                label: 'Usar localização atual',
                selected: selectedCity == null,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await ref.read(climaSelectedCityProvider.notifier).clear();
                  ref.read(climaManualLocationProvider.notifier).state = null;
                  invalidateClimaWeather(ref);
                },
              ),
              const _ClimaSheetDivider(),
              ClimaSettingsOptionRow(
                label: selectedCity?.nome ?? 'Selecionar cidade',
                selected: selectedCity != null,
                trailingIcon: Icons.chevron_right_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  showClimaCitySelection(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ClimaSheetSectionLabel('TEMPERATURA'),
          const SizedBox(height: 8),
          _ClimaSheetOptionGroup(
            children: [
              ClimaSettingsOptionRow(
                label: 'Celsius (°C)',
                selected: unidade == ClimaUnidade.celsius,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(climaUnidadeProvider.notifier).state =
                      ClimaUnidade.celsius;
                },
              ),
              const _ClimaSheetDivider(),
              ClimaSettingsOptionRow(
                label: 'Fahrenheit (°F)',
                selected: unidade == ClimaUnidade.fahrenheit,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(climaUnidadeProvider.notifier).state =
                      ClimaUnidade.fahrenheit;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Componentes internos do sheet ────────────────────────────────────────────

class _ClimaSheetSectionLabel extends StatelessWidget {
  const _ClimaSheetSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: SoloForteSheetTokens.categoryLabel,
      ),
    );
  }
}

class _ClimaSheetOptionGroup extends StatelessWidget {
  const _ClimaSheetOptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(SoloForteSheetTokens.inputRadius),
      ),
      child: Column(children: children),
    );
  }
}

class _ClimaSheetDivider extends StatelessWidget {
  const _ClimaSheetDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: SoloForteSheetTokens.divider,
      ),
    );
  }
}

// ─── Linha de opção ───────────────────────────────────────────────────────────

class ClimaSettingsOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const ClimaSettingsOptionRow({
    super.key,
    required this.label,
    required this.selected,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoloForteSheetTokens.inputRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? SoloForteSheetTokens.chipTextActive
                        : SoloForteSheetTokens.inputText,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: SoloForteSheetTokens.categoryLabel,
                  size: 22,
                )
              else if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: SoloForteSheetTokens.chipTextActive,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
