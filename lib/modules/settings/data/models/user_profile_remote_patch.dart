import '../../domain/entities/user_profile.dart';

class UserProfileRemotePatch {
  const UserProfileRemotePatch({
    required this.profileFields,
    required this.userMetadata,
  });

  final Map<String, dynamic> profileFields;
  final Map<String, dynamic> userMetadata;

  factory UserProfileRemotePatch.fromUpdate({
    required UserProfile updated,
    required Map<String, String?> changedFields,
    required DateTime updatedAt,
  }) {
    final profileFields = <String, dynamic>{
      'updated_at': updatedAt.toIso8601String(),
    };
    final userMetadata = <String, dynamic>{};

    if (changedFields.containsKey('fullName')) {
      profileFields['name'] = updated.fullName ?? '';
    }
    if (changedFields.containsKey('phone')) {
      profileFields['phone'] = updated.phone ?? '';
    }
    if (changedFields.containsKey('photoUrl')) {
      profileFields['photo_url'] = updated.photoUrl ?? '';
    }
    if (changedFields.containsKey('creaNumber')) {
      userMetadata['crea_number'] = updated.creaNumber;
    }

    return UserProfileRemotePatch(
      profileFields: profileFields,
      userMetadata: userMetadata,
    );
  }

  bool get hasProfileChanges => profileFields.length > 1;
  bool get hasUserMetadataChanges => userMetadata.isNotEmpty;
}
