import 'package:url_launcher/url_launcher.dart';

/// Monta URI wa.me com texto e telefone BR opcional.
///
/// [phoneDigitsBrazil]: apenas dígitos locais (sem +55); o prefixo 55 é aplicado
/// como em [ClientDetailScreen] (`wa.me/55...`).
String buildWhatsAppShareUri({
  String? phoneDigitsBrazil,
  required String message,
}) {
  final text = Uri.encodeComponent(message);
  final digits =
      phoneDigitsBrazil?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.isEmpty) {
    return 'https://wa.me/?text=$text';
  }
  final phone = digits.startsWith('55') ? digits : '55$digits';
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
