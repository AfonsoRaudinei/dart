import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/session/local_session_identity.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_orchestrator.dart';
import '../../core/utils/app_logger.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'private_map_screen.dart';

typedef PrivateMapBootstrapResult = ({
  int clientsCount,
  int agendaEventsCount,
});

class PrivateMapRestoreException implements Exception {
  const PrivateMapRestoreException();

  @override
  String toString() =>
      'Não foi possível restaurar os dados. Verifique a conexão.';
}

const _kRestoreTimeout = Duration(seconds: 30);

@visibleForTesting
Future<PrivateMapBootstrapResult> restorePrivateMapLocalData({
  required String userId,
  required int clientsCount,
  required int agendaEventsCount,
  required Future<int> Function() recountClients,
  required Future<int> Function() recountAgenda,
  required Future<void> Function() triggerImmediateSync,
  required String? Function() lastError,
  required bool Function() ranModules,
  required Future<bool> Function() isOnline,
  Duration timeout = _kRestoreTimeout,
}) async {
  if (clientsCount > 0 || userId.isEmpty) {
    return (clientsCount: clientsCount, agendaEventsCount: agendaEventsCount);
  }

  try {
    await triggerImmediateSync().timeout(timeout);
  } on TimeoutException {
    throw const PrivateMapRestoreException();
  } catch (_) {
    throw const PrivateMapRestoreException();
  }

  final error = lastError();
  if (error != null && error.isNotEmpty) {
    throw const PrivateMapRestoreException();
  }

  final nextClients = await recountClients();
  final nextAgenda = await recountAgenda();

  if (nextClients == 0 && !await isOnline()) {
    throw const PrivateMapRestoreException();
  }

  // Sync sem módulos (hydrate antes de registerSyncModules) não é conta nova.
  if (nextClients == 0 && !ranModules()) {
    throw const PrivateMapRestoreException();
  }

  return (clientsCount: nextClients, agendaEventsCount: nextAgenda);
}

final privateMapBootstrapProvider =
    FutureProvider.autoDispose<PrivateMapBootstrapResult>((ref) async {
      final db = await DatabaseHelper.instance.database;
      final userId = LocalSessionIdentity.resolveUserId();

      Future<int> countClients() async {
        if (userId.isEmpty) return 0;
        return Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM clients WHERE user_id = ?',
                [userId],
              ),
            ) ??
            0;
      }

      Future<int> countAgenda() async {
        if (userId.isEmpty) return 0;
        return Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM agenda_events WHERE user_id = ?',
                [userId],
              ),
            ) ??
            0;
      }

      final clientsCount = await countClients();
      final agendaEventsCount = await countAgenda();
      final orchestrator = ref.read(syncOrchestratorProvider);

      return restorePrivateMapLocalData(
        userId: userId,
        clientsCount: clientsCount,
        agendaEventsCount: agendaEventsCount,
        recountClients: countClients,
        recountAgenda: countAgenda,
        triggerImmediateSync: () =>
            orchestrator.triggerSync(SyncPriority.immediate),
        lastError: () => orchestrator.lastError,
        ranModules: () => orchestrator.lastResults.isNotEmpty,
        isOnline: () => ref.read(connectivityServiceProvider).isConnected,
      );
    });

class PrivateMapBootstrapScreen extends ConsumerWidget {
  const PrivateMapBootstrapScreen({super.key, this.mapOverride});

  @visibleForTesting
  final Widget? mapOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(privateMapBootstrapProvider);
    final orchestrator = ref.watch(syncOrchestratorProvider);

    return bootstrap.when(
      loading: () => _BootstrapScaffold(
        title: 'Sincronizando seus dados…',
        subtitle: 'Preparando banco de dados local.',
        showProgress: orchestrator.isSyncing,
        progress: orchestrator.progress,
      ),
      error: (error, st) {
        final isRestore = error is PrivateMapRestoreException;
        if (!isRestore) {
          AppLogger.error(
            'Falha ao inicializar DB no boot do mapa privado',
            tag: 'Bootstrap',
            error: error,
            stackTrace: st,
          );
        }
        return _BootstrapScaffold(
          title: isRestore
              ? 'Não foi possível restaurar os dados. Verifique a conexão.'
              : 'Erro ao iniciar',
          subtitle: isRestore
              ? ''
              : 'Não foi possível preparar os dados locais. Tente novamente.',
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(privateMapBootstrapProvider),
        );
      },
      data: (_) => mapOverride ?? const PrivateMapScreen(),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    color: context.premiumTextSecondary,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.premiumTextSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (showProgress) ...[
                    const SizedBox(height: 22),
                    LinearProgressIndicator(
                      value: progress <= 0 || progress >= 1 ? null : progress,
                      backgroundColor: context.premiumHairline,
                      color: theme.colorScheme.primary,
                      minHeight: 6,
                    ),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          actionLabel!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
