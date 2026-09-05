// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/access/producer_create_context_resolver.dart';
import '../../../../core/contracts/i_active_visit_context_lookup.dart';
import '../../../../core/contracts/i_active_visit_context_lookup_provider.dart';
import '../../../../core/contracts/i_producer_property_gateway_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/session/user_role.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../modules/marketing/domain/entities/marketing_case.dart';
import '../../../../modules/marketing/domain/enums/case_tipo.dart';
import '../../../../modules/marketing/domain/enums/marketing_case_status.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/presentation/screens/novo_case_type_sheets.dart';
import '../../../../modules/marketing/presentation/widgets/draft_saved_sheet.dart';
import '../../../../modules/planos/domain/entities/user_plan.dart';
import '../../../../modules/planos/presentation/providers/plano_providers.dart';
import '../../../../modules/settings/presentation/providers/user_profile_provider.dart';
import '../../../../ui/components/map/widgets/producer_map_context_card.dart';

/// Lança o fluxo completo de criação de novo case a partir de um long-press
/// no mapa. Verifica plano ativo, limite de cases e exibe os sheets adequados.
class NovoCaseModalLauncher {
  const NovoCaseModalLauncher._();

  static Future<void> launch({
    required LatLng position,
    required BuildContext context,
    required WidgetRef ref,
    CaseTipo? initialTipo,
  }) async {
    if (!context.mounted) return;
    final activeVisitContext = await _loadActiveVisitContext(ref);
    if (!context.mounted) return;

    Future<void> handlePublicar(MarketingCase newCase) async {
      await submitCaseFromMap(context: context, ref: ref, newCase: newCase);
    }

    Widget buildCaseSheet() {
      final lat = position.latitude;
      final lng = position.longitude;
      void onClose() => Navigator.of(context).pop();

      switch (initialTipo) {
        case CaseTipo.resultado:
          return NovoResultadoCaseSheet(
            lat: lat,
            lng: lng,
            initialVisitContext: activeVisitContext,
            onClose: onClose,
            onPublicar: handlePublicar,
          );
        case CaseTipo.antesDepois:
          return NovoAntesDepoisCaseSheet(
            lat: lat,
            lng: lng,
            initialVisitContext: activeVisitContext,
            onClose: onClose,
            onPublicar: handlePublicar,
          );
        case CaseTipo.avaliacao:
          return NovaAvaliacaoCaseSheet(
            lat: lat,
            lng: lng,
            initialVisitContext: activeVisitContext,
            onClose: onClose,
            onPublicar: handlePublicar,
          );
        case null:
          return NovoResultadoCaseSheet(
            lat: lat,
            lng: lng,
            initialVisitContext: activeVisitContext,
            onClose: onClose,
            onPublicar: handlePublicar,
          );
      }
    }

    await showSoloForteSheet(
      context: context,
      showDragHandle: false,
      maxHeightFraction: 0.85,
      builder: (sheetContext) {
        final isIos = soloForteSheetIsIos(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: isIos ? SoloForteSheetSkinIos.handleSize.width : 36,
                  height: isIos ? SoloForteSheetSkinIos.handleSize.height : 4,
                  decoration: BoxDecoration(
                    color: isIos
                        ? SoloForteSheetSkinIos.handleColor
                        : Theme.of(sheetContext)
                            .dividerColor
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(child: buildCaseSheet()),
            ],
          ),
        );
      },
    );
  }

  /// Publica case do mapa ou salva rascunho quando o limite de publicados foi atingido.
  static Future<void> submitCaseFromMap({
    required BuildContext context,
    required WidgetRef ref,
    required MarketingCase newCase,
  }) async {
    UserPlan plano;
    try {
      plano = await _resolvePlanoAtivo(ref);
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      _showPlanoLookupError(context, ref, error);
      return;
    }

    if (plano.isAdmin) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await _publishFromMap(
        context: context,
        ref: ref,
        newCase: _asPublishedCase(newCase),
      );
      return;
    }

    final cases = ref.read(marketingCasesProvider).valueOrNull ?? [];
    final casesPublicados = cases
        .where(
          (c) =>
              c.status.toValue() == 'published' &&
              c.ativo &&
              c.deletadoEm == null,
        )
        .length;

    final limite = plano.limiteCases;

    if (casesPublicados >= limite) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      try {
        await ref.read(marketingCasesProvider.notifier).saveAsDraft(newCase);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o rascunho. Tente novamente.',
            ),
          ),
        );
        return;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limite de $limite cases publicados. Salvo como Não gerado em '
            'Relatórios → Marketing.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      final verPlanos = await DraftSavedSheet.show(context);
      if (verPlanos == true && context.mounted) {
        context.go('/planos');
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    await _publishFromMap(
      context: context,
      ref: ref,
      newCase: _asPublishedCase(newCase),
    );
  }

  static Future<void> _publishFromMap({
    required BuildContext context,
    required WidgetRef ref,
    required MarketingCase newCase,
  }) async {
    final outcome = await ref
        .read(marketingCasesProvider.notifier)
        .publishCaseDetailed(newCase);
    if (!context.mounted) return;
    _showPublishOutcome(
      context: context,
      ref: ref,
      outcome: outcome,
      caseToRetry: newCase,
    );
  }

  static MarketingCase _asPublishedCase(MarketingCase newCase) {
    return MarketingCase.fromJson({
      ...newCase.toJson(),
      'status': MarketingCaseStatus.published.toValue(),
      'atualizado_em': DateTime.now().toIso8601String(),
    });
  }

  static Future<UserPlan> _resolvePlanoAtivo(WidgetRef ref) async {
    final async = ref.read(planoAtivoProvider);
    if (async.hasValue && async.value != null) {
      return async.value!;
    }
    if (async.hasError) {
      throw async.error ?? Exception('Erro ao consultar plano');
    }
    return ref.read(planoAtivoProvider.future);
  }

  static Future<ActiveVisitContext?> _loadActiveVisitContext(
    WidgetRef ref,
  ) async {
    try {
      final visit = await ref
          .read(activeVisitContextLookupProvider)
          .getActiveContext();
      if (visit != null) return visit;
    } catch (_) {
      // Sem visita ativa — tenta contexto da propriedade do produtor.
    }

    final role = ref.read(currentUserRoleProvider);
    if (!role.isProdutor) return null;

    try {
      return await ProducerCreateContextResolver.asVisitContext(
        ref.read(producerPropertyGatewayProvider),
        preferredFarmId: ref.read(producerMapSelectedFarmIdProvider),
        preferredFieldId: ref.read(producerMapSelectedFieldIdProvider),
      );
    } catch (_) {
      return null;
    }
  }

  static bool isSessionOrRlsError(Object? error) {
    if (error == null) return false;
    if (error is AuthException) return true;
    if (error is StateError &&
        error.message.contains('Usuario nao autenticado')) {
      return true;
    }
    if (error is PostgrestException) {
      final code = error.code ?? '';
      return code == '42501' || code == 'PGRST301';
    }
    final text = error.toString().toLowerCase();
    return text.contains('jwt') ||
        text.contains('not authenticated') ||
        text.contains('invalid claim');
  }

  static bool isNetworkError(Object? error, {bool? isOnline}) {
    if (isOnline == false) return true;
    return isTransientNetworkPublishError(error);
  }

  static void _showPlanoLookupError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    final isOnline = ref.read(connectivityStateProvider).valueOrNull;
    if (isSessionOrRlsError(error)) {
      _showSnackBar(
        context: context,
        message: 'Sessão expirada. Entre novamente para publicar.',
        backgroundColor: Colors.red,
        icon: Icons.lock_outline,
        actionLabel: 'Entrar',
        onAction: () => context.go('/login'),
      );
      return;
    }

    if (isNetworkError(error, isOnline: isOnline)) {
      _showSnackBar(
        context: context,
        message: 'Sem conexão. Não foi possível verificar seu plano.',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
        actionLabel: 'Tentar novamente',
        onAction: () {
          ref.invalidate(planoAtivoProvider);
        },
      );
      return;
    }

    _showSnackBar(
      context: context,
      message: 'Não foi possível verificar seu plano. Tente novamente.',
      backgroundColor: Colors.orange,
      icon: Icons.error_outline,
      actionLabel: 'Tentar novamente',
      onAction: () {
        ref.invalidate(planoAtivoProvider);
      },
    );
  }

  static void _showPublishOutcome({
    required BuildContext context,
    required WidgetRef ref,
    required PublishOutcome outcome,
    required MarketingCase caseToRetry,
  }) {
    if (outcome.isSuccess) {
      HapticFeedback.heavyImpact();
      _showSnackBar(
        context: context,
        message: 'Case publicado com sucesso! 📈',
        backgroundColor: const Color(0xFF34C759),
        icon: Icons.check_circle,
      );
      return;
    }

    final error = outcome.error;
    final isOnline = ref.read(connectivityStateProvider).valueOrNull;

    if (isSessionOrRlsError(error)) {
      _showSnackBar(
        context: context,
        message: 'Sessão expirada. Entre novamente para publicar.',
        backgroundColor: Colors.red,
        icon: Icons.lock_outline,
        actionLabel: 'Entrar',
        onAction: () => context.go('/login'),
      );
      return;
    }

    if (isNetworkError(error, isOnline: isOnline)) {
      _showSnackBar(
        context: context,
        message: 'Sem conexão — case salvo localmente e será sincronizado.',
        backgroundColor: Colors.orange,
        icon: Icons.cloud_off,
      );
      return;
    }

    _showSnackBar(
      context: context,
      message: 'Não foi possível publicar o case. Tente novamente.',
      backgroundColor: Colors.orange,
      icon: Icons.error_outline,
      actionLabel: 'Tentar novamente',
      onAction: () {
        unawaited(
          _publishFromMap(context: context, ref: ref, newCase: caseToRetry),
        );
      },
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
