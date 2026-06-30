import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/agenda_view.dart';
import '../providers/agenda_filters_provider.dart';
import 'unsaved_changes_dialog.dart';

/// Segmented control estilo iOS para navegação entre views da agenda
class AgendaSegmentedControl extends ConsumerWidget {
  const AgendaSegmentedControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(agendaViewProvider);
    final theme = Theme.of(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF161A1D)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: AgendaView.values.map((view) {
          final isSelected = currentView == view;
          return Expanded(
            child: GestureDetector(
              onTap: () => _handleViewChange(context, ref, view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (theme.brightness == Brightness.dark
                            ? const Color(0xFF1E2428)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    view.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? (theme.brightness == Brightness.dark
                                ? const Color(0xFFE6E6E6)
                                : const Color(0xFF1A1A1A))
                          : (theme.brightness == Brightness.dark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Manipula a mudança de view com verificação de alterações não salvas
  Future<void> _handleViewChange(
    BuildContext context,
    WidgetRef ref,
    AgendaView newView,
  ) async {
    final currentView = ref.read(agendaViewProvider);

    // Se já está na view, não faz nada
    if (currentView == newView) return;

    final hasUnsavedChanges = ref.read(agendaHasUnsavedChangesProvider);

    // Views que precisam de confirmação se houver alterações
    final needsConfirmation = currentView == AgendaView.planejamento;

    // Se não tem alterações ou não precisa confirmação, troca direto
    if (!hasUnsavedChanges || !needsConfirmation) {
      ref.read(agendaViewProvider.notifier).state = newView;
      return;
    }

    // Exibe dialog de confirmação
    final canSwitch = await UnsavedChangesDialog.show(
      context,
      onSave: () async {
        // Limpa o flag de alterações não salvas
        // As alterações já foram persistidas automaticamente pelo provider
        // Este callback é chamado quando o usuário escolhe "Salvar e Continuar"
        ref.read(agendaHasUnsavedChangesProvider.notifier).state = false;
      },
    );

    // Se confirmou, troca a view e limpa o flag
    if (canSwitch) {
      ref.read(agendaHasUnsavedChangesProvider.notifier).state = false;
      ref.read(agendaViewProvider.notifier).state = newView;
    }
  }
}
