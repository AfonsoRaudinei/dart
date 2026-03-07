import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/public/providers/public_location_provider.dart';

/// Botão flutuante de localização para o mapa público.
///
/// Posicionado no canto superior direito, permite ao usuário:
/// - Solicitar permissão de GPS
/// - Centralizar o mapa na sua localização atual
/// - Ver feedback visual do estado (loading, ativo, erro)
class LocationButton extends ConsumerWidget {
  final VoidCallback? onLocationObtained;

  const LocationButton({super.key, this.onLocationObtained});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(publicLocationNotifierProvider);

    return Semantics(
      label: _getSemanticLabel(locationState.status),
      button: true,
      enabled: locationState.status != PublicLocationStatus.loading,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await ref
                  .read(publicLocationNotifierProvider.notifier)
                  .requestLocation();

              // Callback após obter localização - verifica o estado ATUALIZADO
              final updatedState = ref.read(publicLocationNotifierProvider);
              if (updatedState.status == PublicLocationStatus.available &&
                  onLocationObtained != null) {
                onLocationObtained!();
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: _buildIcon(locationState.status),
          ),
        ),
      ),
    );
  }

  String _getSemanticLabel(PublicLocationStatus status) {
    switch (status) {
      case PublicLocationStatus.initial:
        return 'Ativar localização';
      case PublicLocationStatus.loading:
        return 'Obtendo localização...';
      case PublicLocationStatus.available:
        return 'Centralizar no mapa';
      case PublicLocationStatus.error:
      case PublicLocationStatus.permissionDenied:
      case PublicLocationStatus.serviceDisabled:
        return 'Erro ao obter localização. Toque para tentar novamente';
    }
  }

  Widget _buildIcon(PublicLocationStatus status) {
    switch (status) {
      case PublicLocationStatus.loading:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                PremiumTokens.brandGreen,
              ),
            ),
          ),
        );

      case PublicLocationStatus.available:
        return const Icon(
          Icons.my_location,
          color: PremiumTokens.brandGreen,
          size: 24,
        );

      case PublicLocationStatus.permissionDenied:
      case PublicLocationStatus.serviceDisabled:
      case PublicLocationStatus.error:
        return const Icon(
          Icons.location_off,
          color: Color(0xFFFF3B30),
          size: 24,
        );

      case PublicLocationStatus.initial:
        return const Icon(
          Icons.location_searching,
          color: PremiumTokens.textSecondaryLight,
          size: 24,
        );
    }
  }
}
