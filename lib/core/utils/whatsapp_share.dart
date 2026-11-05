import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Normaliza dígitos BR para segmento wa.me (sem `?text=`).
///
/// Até 11 dígitos = número local → prefixo `55`.
/// Acima de 11 dígitos com `55` inicial = já inclui país.
@visibleForTesting
String whatsAppPhonePathSegment(String? phoneDigitsBrazil) {
  final digits =
      phoneDigitsBrazil?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.isEmpty) return '';
  if (digits.length <= 11) {
    return '55$digits';
  }
  if (digits.startsWith('55')) {
    return digits;
  }
  return '55$digits';
}

/// Monta URI wa.me com texto e telefone BR opcional.
///
/// [phoneDigitsBrazil]: apenas dígitos locais (sem +55); regra em
/// [whatsAppPhonePathSegment].
String buildWhatsAppShareUri({
  String? phoneDigitsBrazil,
  required String message,
}) {
  final text = Uri.encodeComponent(message);
  final phone = whatsAppPhonePathSegment(phoneDigitsBrazil);
  if (phone.isEmpty) {
    return 'https://wa.me/?text=$text';
  }
  return 'https://wa.me/$phone?text=$text';
}

Future<void> launchWhatsAppShare({
  String? phoneDigitsBrazil,
  required String message,
}) async {
  final url = buildWhatsAppShareUri(
    phoneDigitsBrazil: phoneDigitsBrazil,
    message: message,
  );
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) {
    throw StateError('Não foi possível abrir o WhatsApp.');
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
