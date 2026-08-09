/// Critérios de visibilidade da aba Relatórios → Gerados (Publicações).
///
/// Fonte da verdade: ADR-051. Implementação do adapter em
/// `marketing/infra/marketing_case_reports_list_impl_provider`.
bool isEligibleForGeradosTab({
  required String statusValue,
  required bool ativo,
  required DateTime? deletadoEm,
}) {
  if (deletadoEm != null) return false;
  if (!ativo) return false;
  return statusValue == 'published';
}
