import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/sync_orchestrator.dart';
import '../../core/utils/app_logger.dart';
import 'private_map_screen.dart';

typedef _BootstrapResult = ({
  int clientsCount,
  int agendaEventsCount,
});

final _privateMapBootstrapProvider =
    FutureProvider.autoDispose<_BootstrapResult>((ref) async {
      // Força migrações/abertura de DB antes de construir o mapa privado.
      final db = await DatabaseHelper.instance.database;

      final clientsCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM clients')) ??
          0;
      final agendaEventsCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM agenda_events')) ??
          0;

      return (clientsCount: clientsCount, agendaEventsCount: agendaEventsCount);
    });

class PrivateMapBootstrapScreen extends ConsumerWidget {
  const PrivateMapBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(_privateMapBootstrapProvider);
    final orchestrator = ref.watch(syncOrchestratorProvider);

    return bootstrap.when(
      loading: () => _BootstrapScaffold(
        title: 'Carregando dados…',
        subtitle: 'Preparando banco de dados local.',
        showProgress: orchestrator.isSyncing,
        progress: orchestrator.progress,
      ),
      error: (error, st) {
        AppLogger.error(
          'Falha ao inicializar DB no boot do mapa privado',
          tag: 'Bootstrap',
          error: error,
          stackTrace: st,
        );
        return _BootstrapScaffold(
          title: 'Erro ao iniciar',
          subtitle: 'Não foi possível preparar os dados locais. Tente novamente.',
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(_privateMapBootstrapProvider),
        );
      },
      data: (result) {
        final hasAnyLocalData =
            result.clientsCount > 0 || result.agendaEventsCount > 0;

        if (hasAnyLocalData) {
          return const PrivateMapScreen();
        }

        // Primeira execução ou cache vazio: evita tela preta e orienta o usuário.
        return _BootstrapScaffold(
          title: 'Sem dados locais',
          subtitle:
              'Conecte-se à internet e sincronize para baixar seus dados.',
          showProgress: orchestrator.isSyncing,
          progress: orchestrator.progress,
          actionLabel: orchestrator.isSyncing ? 'Sincronizando…' : 'Sincronizar agora',
          onAction: orchestrator.isSyncing
              ? null
              : () async {
                  try {
                    await ref
                        .read(syncOrchestratorProvider)
                        .triggerSync(SyncPriority.immediate);
                  } finally {
                    ref.invalidate(_privateMapBootstrapProvider);
                  }
                },
        );
      },
    );
  }
}

class _BootstrapScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showProgress;
  final double progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _BootstrapScaffold({
    required this.title,
    required this.subtitle,
    this.showProgress = false,
    this.progress = 0,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🛡 IPA-120: fundo branco garante legibilidade mesmo sem fontes
      // customizadas no bundle. Fundo preto causava tela preta no IPA 119.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storage_outlined,
                    color: Color(0xFF888888),
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      height: 1.4,
                      fontFamily: null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 22),
                    LinearProgressIndicator(
                      value: progress <= 0 || progress >= 1 ? null : progress,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFF34C759),
                      minHeight: 6,
                    ),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          actionLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

