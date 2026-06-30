enum AuthDeepLinkType { recovery, signup, unknown }

class AuthDeepLinkIntent {
  const AuthDeepLinkIntent({
    required this.type,
    required this.hasCredentials,
    required this.hasError,
  });

  final AuthDeepLinkType type;
  final bool hasCredentials;
  final bool hasError;

  static AuthDeepLinkIntent parse(Uri uri) {
    final rawParams = uri.fragment.isNotEmpty ? uri.fragment : uri.query;
    if (rawParams.isEmpty) {
      return const AuthDeepLinkIntent(
        type: AuthDeepLinkType.unknown,
        hasCredentials: false,
        hasError: false,
      );
    }

    try {
      final params = Uri.splitQueryString(rawParams);
      final type = switch (params['type']) {
        'recovery' => AuthDeepLinkType.recovery,
        'signup' => AuthDeepLinkType.signup,
        _ => AuthDeepLinkType.unknown,
      };
      return AuthDeepLinkIntent(
        type: type,
        hasCredentials:
            params['access_token']?.isNotEmpty == true ||
            params['refresh_token']?.isNotEmpty == true ||
            params['code']?.isNotEmpty == true,
        hasError:
            params['error']?.isNotEmpty == true ||
            params['error_description']?.isNotEmpty == true,
      );
    } on FormatException {
      return const AuthDeepLinkIntent(
        type: AuthDeepLinkType.unknown,
        hasCredentials: false,
        hasError: true,
      );
    }
  }
}
