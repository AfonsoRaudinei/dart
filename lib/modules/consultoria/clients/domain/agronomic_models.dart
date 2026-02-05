class Talhao {
  final String id;
  final String name; // nome ou código
  final double areaHa;
  final String crop; // Cultura (ex: Soja, Milho)
  final String harvest; // Safra (ex: 2024/2025)
  final DateTime? updatedAt;
  final Map<String, dynamic>? geometry; // GeoJSON

  Talhao({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.crop,
    required this.harvest,
    this.updatedAt,
    this.geometry,
  });

  Talhao copyWith({
    String? id,
    String? name,
    double? areaHa,
    String? crop,
    String? harvest,
    DateTime? updatedAt,
    Map<String, dynamic>? geometry,
  }) {
    return Talhao(
      id: id ?? this.id,
      name: name ?? this.name,
      areaHa: areaHa ?? this.areaHa,
      crop: crop ?? this.crop,
      harvest: harvest ?? this.harvest,
      updatedAt: updatedAt ?? this.updatedAt,
      geometry: geometry ?? this.geometry,
    );
  }
}

class Farm {
  final String id;
  final String name;
  final String city;
  final String state;
  final double totalAreaHa; // Pode ser soma dos talhões ou declarado
  final List<Talhao> fields;

  Farm({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.totalAreaHa,
    this.fields = const [],
  });

  Farm copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    double? totalAreaHa,
    List<Talhao>? fields,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      totalAreaHa: totalAreaHa ?? this.totalAreaHa,
      fields: fields ?? this.fields,
    );
  }
}
