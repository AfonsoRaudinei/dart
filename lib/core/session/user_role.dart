enum UserRole { produtor, consultor, unknown }

extension UserRoleParsing on String? {
  UserRole toUserRole() {
    final normalized = (this ?? '').trim().toLowerCase();
    return switch (normalized) {
      'produtor' => UserRole.produtor,
      'consultor' => UserRole.consultor,
      _ => UserRole.unknown,
    };
  }
}

extension UserRoleValue on UserRole {
  String get value => switch (this) {
    UserRole.produtor => 'produtor',
    UserRole.consultor => 'consultor',
    UserRole.unknown => '',
  };

  String get label => switch (this) {
    UserRole.produtor => 'Produtor',
    UserRole.consultor => 'Consultor',
    UserRole.unknown => 'Conta',
  };

  bool get isProdutor => this == UserRole.produtor;
  bool get isConsultor => this == UserRole.consultor;
  bool get isUnknown => this == UserRole.unknown;
}
