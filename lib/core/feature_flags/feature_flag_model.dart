/// Modelo de Feature Flag para controle de rollout progressivo.
///
/// Representa uma flag de funcionalidade que pode ser ativada/desativada
/// remotamente, com suporte a rollout percentual e filtragem por papel.
class FeatureFlag {
  /// Identificador único da feature (ex: 'drawing_v1')
  final String key;

  /// Flag global de ativação. Se false, desativa completamente.
  final bool enabled;

  /// Percentual de rollout (0-100). Usado com hash determinístico do userId.
  final int rolloutPercentage;

  /// Papéis permitidos para usar a feature (ex: ['consultor', 'produtor']).
  /// Se null ou vazio, qualquer papel pode acessar (se outras condições ok).
  final List<String>? allowedRoles;

  /// Versão da flag para invalidação de cache.
  final int version;

  /// Versão mínima do app necessária (opcional).
  final String? minAppVersion;

  const FeatureFlag({
    required this.key,
    required this.enabled,
    required this.rolloutPercentage,
    this.allowedRoles,
    required this.version,
    this.minAppVersion,
  });

  /// Factory para criar uma flag completamente desativada (kill switch).
  factory FeatureFlag.disabled(String key) {
    return FeatureFlag(
      key: key,
      enabled: false,
      rolloutPercentage: 0,
      version: 0,
    );
  }

  /// Factory para criar uma flag 100% ativa (rollout completo).
  factory FeatureFlag.fullyEnabled(String key, {int version = 1}) {
    return FeatureFlag(
      key: key,
      enabled: true,
      rolloutPercentage: 100,
      version: version,
    );
  }

  /// Deserialização de JSON do backend.
  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      key: json['key'] as String,
      enabled: json['enabled'] as bool,
      rolloutPercentage: json['rollout_percentage'] as int,
      allowedRoles: (json['allowed_roles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      version: json['version'] as int,
      minAppVersion: json['min_app_version'] as String?,
    );
  }

  /// Serialização para JSON (útil para cache local).
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'enabled': enabled,
      'rollout_percentage': rolloutPercentage,
      'allowed_roles': allowedRoles,
      'version': version,
      'min_app_version': minAppVersion,
    };
  }

  @override
  String toString() {
    return 'FeatureFlag('
        'key: $key, '
        'enabled: $enabled, '
        'rollout: $rolloutPercentage%, '
        'roles: $allowedRoles, '
        'v$version)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureFlag &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          enabled == other.enabled &&
          rolloutPercentage == other.rolloutPercentage &&
          _listEquals(allowedRoles, other.allowedRoles) &&
          version == other.version &&
          minAppVersion == other.minAppVersion;

  @override
  int get hashCode =>
      key.hashCode ^
      enabled.hashCode ^
      rolloutPercentage.hashCode ^
      allowedRoles.hashCode ^
      version.hashCode ^
      minAppVersion.hashCode;

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
