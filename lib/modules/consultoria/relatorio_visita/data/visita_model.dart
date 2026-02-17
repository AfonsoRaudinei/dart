import 'package:uuid/uuid.dart';

class VisitaModel {
  final String id;
  String produtor;
  String propriedade;
  DateTime dataVisita;
  double? area;
  String? cultivar;
  DateTime? dataPlantio;
  String? estagioCodigo;
  List<String> categorias;
  String observacoes;
  String tecnico;
  double latitude;
  double longitude;
  Map<String, Map<String, dynamic>> detalhes;
  Map<String, List<String>> fotos; // categoryId -> [local_paths]
  final DateTime createdAt;

  VisitaModel({
    String? id,
    this.produtor = '',
    this.propriedade = '',
    required this.dataVisita,
    this.area,
    this.cultivar,
    this.dataPlantio,
    this.estagioCodigo,
    this.categorias = const [],
    this.observacoes = '',
    this.tecnico = '',
    required this.latitude,
    required this.longitude,
    Map<String, Map<String, dynamic>>? detalhes,
    Map<String, List<String>>? fotos,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       detalhes = detalhes ?? {},
       fotos = fotos ?? {},
       createdAt = createdAt ?? DateTime.now();

  int get dap {
    if (dataPlantio == null) return 0;
    final diff = dataVisita.difference(dataPlantio!).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Serialização JSON simples para o banco e SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produtor': produtor,
      'propriedade': propriedade,
      'dataVisita': dataVisita.toIso8601String(),
      'area': area,
      'cultivar': cultivar,
      'dataPlantio': dataPlantio?.toIso8601String(),
      'estagioCodigo': estagioCodigo,
      'categorias': categorias,
      'observacoes': observacoes,
      'tecnico': tecnico,
      'latitude': latitude,
      'longitude': longitude,
      'detalhes': detalhes,
      'fotos': fotos,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VisitaModel.fromJson(Map<String, dynamic> json) {
    return VisitaModel(
      id: json['id'],
      produtor: json['produtor'] ?? '',
      propriedade: json['propriedade'] ?? '',
      dataVisita: DateTime.parse(json['dataVisita']),
      area: (json['area'] as num?)?.toDouble(),
      cultivar: json['cultivar'],
      dataPlantio: json['dataPlantio'] != null
          ? DateTime.parse(json['dataPlantio'])
          : null,
      estagioCodigo: json['estagioCodigo'],
      categorias: List<String>.from(json['categorias'] ?? []),
      observacoes: json['observacoes'] ?? '',
      tecnico: json['tecnico'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      detalhes:
          (json['detalhes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
          ) ??
          {},
      fotos:
          (json['fotos'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          ) ??
          {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  VisitaModel copyWith({
    String? produtor,
    String? propriedade,
    DateTime? dataVisita,
    double? area,
    String? cultivar,
    DateTime? dataPlantio,
    String? estagioCodigo,
    List<String>? categorias,
    String? observacoes,
    String? tecnico,
    Map<String, Map<String, dynamic>>? detalhes,
  }) {
    return VisitaModel(
      id: id,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      produtor: produtor ?? this.produtor,
      propriedade: propriedade ?? this.propriedade,
      dataVisita: dataVisita ?? this.dataVisita,
      area: area ?? this.area,
      cultivar: cultivar ?? this.cultivar,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      estagioCodigo: estagioCodigo ?? this.estagioCodigo,
      categorias: categorias ?? this.categorias,
      observacoes: observacoes ?? this.observacoes,
      tecnico: tecnico ?? this.tecnico,
      detalhes: detalhes ?? this.detalhes,
    );
  }
}
