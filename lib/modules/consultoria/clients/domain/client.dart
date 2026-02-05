import 'agronomic_models.dart';

class Client {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String state;
  final String? email;
  final String? observation;
  final String? photoPath;
  final bool active;
  final DateTime createdAt;
  final List<Farm> farms;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.state,
    this.email,
    this.observation,
    this.photoPath,
    this.active = true,
    required this.createdAt,
    this.farms = const [],
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? state,
    String? email,
    String? observation,
    String? photoPath,
    bool? active,
    DateTime? createdAt,
    List<Farm>? farms,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      email: email ?? this.email,
      observation: observation ?? this.observation,
      photoPath: photoPath ?? this.photoPath,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      farms: farms ?? this.farms,
    );
  }
}
