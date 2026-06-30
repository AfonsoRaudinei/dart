// ADR-032 — settings/domain/entities/user_profile.dart
//
// Entidade imutável do perfil do usuário autenticado.
// Fonte da verdade: Supabase Auth + tabela `perfis` + cache SQLite (v30).
//
// Campos somente leitura: id, email, role, createdAt
// Campos editáveis: fullName, phone, photoUrl, creaNumber

class UserProfile {
  final String id; // Supabase auth.uid — somente leitura
  final String email; // Supabase auth.email — somente leitura
  final String? fullName; // perfis.name — editável
  final String? phone; // perfis.phone — editável
  final String? role; // perfis.role — somente leitura
  final String? photoUrl; // perfis.photo_url — editável (via fluxo Storage)
  final String? creaNumber; // userMetadata['crea_number'] — editável
  final DateTime createdAt; // Supabase createdAt — somente leitura
  final DateTime updatedAt; // atualizado a cada edição confirmada

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.photoUrl,
    this.creaNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retorna cópia com campos editáveis substituídos.
  /// Campos somente leitura (id, email, role, createdAt) nunca mudam.
  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? creaNumber,
    bool clearFullName = false,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
    bool clearCreaNumber = false,
    DateTime? updatedAt,
  }) {
    assert(!clearFullName || fullName == null);
    assert(!clearPhone || phone == null);
    assert(!clearPhotoUrl || photoUrl == null);
    assert(!clearCreaNumber || creaNumber == null);

    return UserProfile(
      id: id,
      email: email,
      fullName: clearFullName ? null : fullName ?? this.fullName,
      phone: clearPhone ? null : phone ?? this.phone,
      role: role,
      photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
      creaNumber: clearCreaNumber ? null : creaNumber ?? this.creaNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCache() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'role': role,
    'photo_url': photoUrl,
    'crea_number': creaNumber,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'sync_status': 0,
  };

  factory UserProfile.fromCache(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    email: map['email'] as String,
    fullName: map['full_name'] as String?,
    phone: map['phone'] as String?,
    role: map['role'] as String?,
    photoUrl: map['photo_url'] as String?,
    creaNumber: map['crea_number'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
  );
}
