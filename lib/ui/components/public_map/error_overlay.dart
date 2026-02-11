import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

/// Overlay de erro para o mapa público.
///
/// Exibe mensagem de erro com opção de retry, sem bloquear
/// totalmente a visualização do mapa.
class PublicMapErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const PublicMapErrorOverlay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(SoloSpacing.md),
          decoration: BoxDecoration(
            color: SoloForteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF5252).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Ícone de erro
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF5252),
                  size: 20,
                ),
              ),
              const SizedBox(width: SoloSpacing.md),
              // Mensagem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ops!',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 14,
                        fontWeight: SoloFontWeights.semibold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: SoloTextStyles.body.copyWith(
                        fontSize: 13,
                        color: SoloForteColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão Retry
              if (onRetry != null) ...[
                const SizedBox(width: SoloSpacing.sm),
                Semantics(
                  label: 'Tentar novamente',
                  button: true,
                  child: Material(
                    color: SoloForteColors.brand,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SoloSpacing.md,
                          vertical: SoloSpacing.sm,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: SoloForteColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog de permissão de GPS.
///
/// Exibido quando o usuário não concedeu permissão de localização.
class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LocationPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SoloForteColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: SoloForteColors.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: SoloSpacing.md),
          Expanded(
            child: Text(
              'Localização',
              style: SoloTextStyles.headingMedium.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para centralizar o mapa na sua localização, precisamos de permissão para acessar o GPS.',
            style: SoloTextStyles.body.copyWith(
              color: SoloForteColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: SoloSpacing.md),
          Container(
            padding: const EdgeInsets.all(SoloSpacing.md),
            decoration: BoxDecoration(
              color: SoloForteColors.grayLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: SoloForteColors.textSecondary,
                ),
                const SizedBox(width: SoloSpacing.sm),
                Expanded(
                  child: Text(
                    'Suas informações de localização são usadas apenas para melhorar sua experiência no app.',
                    style: SoloTextStyles.body.copyWith(
                      fontSize: 12,
                      color: SoloForteColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Não agora',
            style: SoloTextStyles.body.copyWith(
              color: SoloForteColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: SoloForteColors.brand,
            foregroundColor: SoloForteColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Permitir'),
        ),
      ],
    );
  }
}
