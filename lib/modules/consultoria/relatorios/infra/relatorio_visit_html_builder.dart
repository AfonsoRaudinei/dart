import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/html_templates/visita_html_renderer.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/providers/user_profile_provider.dart';
import '../../publicacoes/providers/publicacao_providers.dart';
import '../models/relatorio_tecnico.dart';

class ReportBrandingContext {
  final String? brandName;
  final String? logoPath;
  final String consultantName;
  final String? consultantRole;

  const ReportBrandingContext({
    required this.brandName,
    required this.logoPath,
    required this.consultantName,
    required this.consultantRole,
  });
}

Future<ReportBrandingContext> resolveReportBrandingContext(
  WidgetRef ref, {
  required String fallbackConsultantName,
  String? fallbackConsultantRole,
}) async {
  await ref.read(reportBrandingProvider.notifier).refreshRemote();
  final branding = ref.read(reportBrandingProvider);
  UserProfile? profile;
  try {
    profile = await ref.read(currentUserProfileProvider.future);
  } catch (_) {
    profile = null;
  }

  final consultantName = (profile?.fullName?.trim().isNotEmpty ?? false)
      ? profile!.fullName!.trim()
      : fallbackConsultantName;
  final consultantRole = (profile?.role?.trim().isNotEmpty ?? false)
      ? profile!.role!.trim()
      : fallbackConsultantRole;

  return ReportBrandingContext(
    brandName: branding.brandName,
    logoPath: branding.logoPath,
    consultantName: consultantName,
    consultantRole: consultantRole,
  );
}

Future<String> buildRelatorioVisitHtml(
  WidgetRef ref,
  RelatorioTecnico relatorio,
) async {
  final clienteNome = await _resolveClienteNome(ref, relatorio);
  final publicacoesTitulos = await _resolvePublicacoesTitulos(ref, relatorio);
  final branding = await resolveReportBrandingContext(
    ref,
    fallbackConsultantName: _resolveAgronomistNome(relatorio),
    fallbackConsultantRole: 'Consultoria',
  );

  return VisitaHtmlRenderer.render(
    relatorio: relatorio.toJson(),
    agronomistNome: branding.consultantName,
    clienteNome: clienteNome,
    publicacoesTitulos: publicacoesTitulos,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantRole: branding.consultantRole,
  );
}

Future<String> _resolveClienteNome(
  WidgetRef ref,
  RelatorioTecnico relatorio,
) async {
  try {
    final client = await ref
        .read(clientLookupProvider)
        .findById(relatorio.clientId);
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
  } catch (_) {
    // Lookup pode não estar registrado em testes isolados.
  }
  return relatorio.clientId;
}

Future<Map<String, String>> _resolvePublicacoesTitulos(
  WidgetRef ref,
  RelatorioTecnico relatorio,
) async {
  final titles = <String, String>{};
  for (final id in relatorio.publicacoesRefs) {
    try {
      final publicacao = await ref.read(publicacaoDetailProvider(id: id).future);
      final title = publicacao?.titulo.trim();
      titles[id] = title != null && title.isNotEmpty ? title : id;
    } catch (_) {
      titles[id] = id;
    }
  }
  return titles;
}

String _resolveAgronomistNome(RelatorioTecnico relatorio) {
  final user = Supabase.instance.client.auth.currentUser;
  final metadata = user?.userMetadata ?? const <String, dynamic>{};
  final fullName = metadata['full_name']?.toString().trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;
  final name = metadata['name']?.toString().trim();
  if (name != null && name.isNotEmpty) return name;
  final email = user?.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  return relatorio.agronomistId;
}
