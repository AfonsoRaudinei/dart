import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

// ─── Função de exibição ───────────────────────────────────────────────────────

/// Abre o painel de configurações do módulo Clima via modal bottom sheet.
void showClimaSettings(BuildContext context) {
  showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (_) => const ClimaSettingsSheet(),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class ClimaSettingsSheet extends ConsumerWidget {
  const ClimaSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unidade = ref.watch(climaUnidadeProvider);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              decoration: BoxDecoration(
                color: kClimaDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Título ────────────────────────────────────────────────────────
          const Text(
            'Configurações',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.37,
              color: kClimaTextPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Seção Temperatura ─────────────────────────────────────────────
          const Text(
            'TEMPERATURA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: kClimaTextTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kClimaBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  label: 'Celsius (°C)',
                  selected: unidade == ClimaUnidade.celsius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(climaUnidadeProvider.notifier).state =
                        ClimaUnidade.celsius;
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, thickness: 0.5, color: kClimaDivider),
                ),
                _SettingsRow(
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
          ),
        ],
      ),
    );
  }
}

// ─── Linha de opção ───────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: kClimaTextPrimary,
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: kClimaTint, size: 20),
          ],
        ),
      ),
    );
  }
}
