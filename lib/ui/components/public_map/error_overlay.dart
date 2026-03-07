import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
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
                child: Icon(icon, color: const Color(0xFFFF5252), size: 20),
              ),
              const SizedBox(width: 16.0),
              // Mensagem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ops!',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14).copyWith(
                        fontSize: 13,
                        color: PremiumTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão Retry
              if (onRetry != null) ...[
                const SizedBox(width: 12.0),
                Semantics(
                  label: 'Tentar novamente',
                  button: true,
                  child: Material(
                    color: PremiumTokens.brandGreen,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PremiumTokens.brandGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: PremiumTokens.brandGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              'Localização',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600).copyWith(fontSize: 18),
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
            style: const TextStyle(fontSize: 14).copyWith(
              color: PremiumTokens.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: PremiumTokens.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: PremiumTokens.textSecondaryLight,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Suas informações de localização são usadas apenas para melhorar sua experiência no app.',
                    style: const TextStyle(fontSize: 14).copyWith(
                      fontSize: 12,
                      color: PremiumTokens.textSecondaryLight,
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
            style: const TextStyle(fontSize: 14).copyWith(
              color: PremiumTokens.textSecondaryLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: PremiumTokens.brandGreen,
            foregroundColor: Colors.white,
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
