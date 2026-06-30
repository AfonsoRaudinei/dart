import 'user_role.dart';

class ProfileRoleResolver {
  const ProfileRoleResolver._();

  static String resolve({
    String? pendingSignupRole,
    required String? metadataRole,
    required String? profileRole,
  }) {
    // `perfis.role` é a fonte remota autoritativa. user_metadata e cache
    // local são apenas fallbacks de bootstrap e não podem elevar privilégios.
    final profile = profileRole.toUserRole();
    if (!profile.isUnknown) return profile.value;

    final metadata = metadataRole.toUserRole();
    if (!metadata.isUnknown) return metadata.value;

    final pending = pendingSignupRole.toUserRole();
    if (!pending.isUnknown) return pending.value;

    return UserRole.produtor.value;
  }

  static bool shouldUpdateProfileRole({
    String? pendingSignupRole,
    required String? metadataRole,
    required String? profileRole,
  }) {
    final resolved = resolve(
      pendingSignupRole: pendingSignupRole,
      metadataRole: metadataRole,
      profileRole: profileRole,
    ).toUserRole();
    return profileRole.toUserRole() != resolved;
  }
}
