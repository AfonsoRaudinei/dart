import 'dart:io';

class RegisterDto {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role; // 'produtor' | 'consultor'
  final File? photo;

  RegisterDto({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.photo,
  });

  Map<String, dynamic> toUserMap(String userId, String? photoUrl) {
    return {
      'id': userId,
      'name': name,
      'phone': phone,
      'role': role,
      'photo_url': photoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RegisterDto &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.password == password &&
        other.role == role &&
        other.photo?.path == photo?.path;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        password.hashCode ^
        role.hashCode ^
        (photo?.path).hashCode;
  }
}
