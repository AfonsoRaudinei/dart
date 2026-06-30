import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

Future<bool> openPrivacyPolicy() => _openUrl(AppConfig.privacyPolicyUrl);

Future<bool> openTermsOfService() => _openUrl(AppConfig.termsOfServiceUrl);

Future<bool> openLgpdContact() =>
    _openUrl('mailto:${AppConfig.lgpdContactEmail}');

Future<bool> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
