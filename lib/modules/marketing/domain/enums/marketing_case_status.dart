enum MarketingCaseStatus {
  draft('draft'),
  pendingSync('pending_sync'),
  published('published'),
  pendingApproval('pending_approval'),
  archived('archived');

  final String value;
  const MarketingCaseStatus(this.value);

  String toValue() => value;

  static MarketingCaseStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return MarketingCaseStatus.draft;
      case 'pending_sync':
        return MarketingCaseStatus.pendingSync;
      case 'published':
        return MarketingCaseStatus.published;
      case 'pending_approval':
        return MarketingCaseStatus.pendingApproval;
      case 'archived':
        return MarketingCaseStatus.archived;
      default:
        return MarketingCaseStatus.published; // default retrocompatível
    }
  }
}
