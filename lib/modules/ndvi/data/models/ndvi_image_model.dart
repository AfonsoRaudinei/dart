import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

class NdviImageModel {
  final String id;
  final String fieldId;
  final String imageDate;
  final double ndviMin;
  final double ndviMax;
  final double ndviMean;
  final String? imageUrl;
  final String? localPath;
  final String source;
  final String fetchedAt;
  final int syncStatus;

  const NdviImageModel({
    required this.id,
    required this.fieldId,
    required this.imageDate,
    required this.ndviMin,
    required this.ndviMax,
    required this.ndviMean,
    required this.source,
    required this.fetchedAt,
    required this.syncStatus,
    this.imageUrl,
    this.localPath,
  });

  factory NdviImageModel.fromMap(Map<String, dynamic> map) {
    return NdviImageModel(
      id: map['id'] as String,
      fieldId: map['field_id'] as String,
      imageDate: map['image_date'] as String,
      ndviMin: (map['ndvi_min'] as num?)?.toDouble() ?? 0.0,
      ndviMax: (map['ndvi_max'] as num?)?.toDouble() ?? 0.0,
      ndviMean: (map['ndvi_mean'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] as String?,
      localPath: map['local_path'] as String?,
      source: map['source'] as String,
      fetchedAt: map['fetched_at'] as String,
      syncStatus: map['sync_status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_id': fieldId,
      'image_date': imageDate,
      'ndvi_min': ndviMin,
      'ndvi_max': ndviMax,
      'ndvi_mean': ndviMean,
      'image_url': imageUrl,
      'local_path': localPath,
      'source': source,
      'fetched_at': fetchedAt,
      'sync_status': syncStatus,
    };
  }

  NdviImage toEntity() {
    return NdviImage(
      id: id,
      fieldId: fieldId,
      imageDate: DateTime.parse(imageDate),
      ndviMin: ndviMin,
      ndviMax: ndviMax,
      ndviMean: ndviMean,
      imageUrl: imageUrl,
      localPath: localPath,
      source: source,
      fetchedAt: DateTime.parse(fetchedAt),
      syncStatus: syncStatus,
    );
  }

  factory NdviImageModel.fromEntity(NdviImage entity) {
    return NdviImageModel(
      id: entity.id,
      fieldId: entity.fieldId,
      imageDate: entity.imageDate.toIso8601String(),
      ndviMin: entity.ndviMin,
      ndviMax: entity.ndviMax,
      ndviMean: entity.ndviMean,
      imageUrl: entity.imageUrl,
      localPath: entity.localPath,
      source: entity.source,
      fetchedAt: entity.fetchedAt.toIso8601String(),
      syncStatus: entity.syncStatus,
    );
  }
}
