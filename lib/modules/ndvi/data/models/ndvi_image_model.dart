import 'dart:convert';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

/// Model de dados — mapeia JSON da Edge Function e rows do SQLite.
class NdviImageModel {
  final String areaId;
  final String date;        // YYYY-MM-DD
  final String? imageBase64;
  final String? imagePath;  // path local — preenche após cache
  final String source;
  final double? cloudCoverage;
  final List<String> availableDates;
  final String cachedAt;

  const NdviImageModel({
    required this.areaId,
    required this.date,
    this.imageBase64,
    this.imagePath,
    required this.source,
    this.cloudCoverage,
    required this.availableDates,
    required this.cachedAt,
  });

  // ── De JSON da Edge Function ──────────────────────────────────────────────

  factory NdviImageModel.fromEdgeJson(Map<String, dynamic> json) {
    final rawDates = json['available_dates'] as List<dynamic>? ?? [];
    return NdviImageModel(
      areaId: json['area_id'] as String,
      date: json['date'] as String,
      imageBase64: json['image_base64'] as String?,
      imagePath: null,
      source: json['source'] as String? ?? 'sentinel',
      cloudCoverage: (json['cloud_coverage'] as num?)?.toDouble(),
      availableDates: rawDates.cast<String>(),
      cachedAt: DateTime.now().toIso8601String(),
    );
  }

  // ── De row SQLite ─────────────────────────────────────────────────────────

  factory NdviImageModel.fromSqliteRow(Map<String, Object?> row) {
    final rawDates = row['available_dates'] as String? ?? '[]';
    final List<dynamic> decoded = jsonDecode(rawDates);
    return NdviImageModel(
      areaId: row['area_id'] as String,
      date: row['date'] as String,
      imageBase64: null,
      imagePath: row['image_path'] as String?,
      source: row['source'] as String,
      cloudCoverage: (row['cloud_coverage'] as num?)?.toDouble(),
      availableDates: decoded.cast<String>(),
      cachedAt: row['cached_at'] as String,
    );
  }

  // ── Para row SQLite ───────────────────────────────────────────────────────

  Map<String, Object?> toSqliteRow(String id) => {
        'id': id,
        'area_id': areaId,
        'date': date,
        'source': source,
        'image_path': imagePath ?? '',
        'cloud_coverage': cloudCoverage,
        'available_dates': jsonEncode(availableDates),
        'cached_at': cachedAt,
      };

  // ── Para entidade de domínio ──────────────────────────────────────────────

  NdviImage toEntity() {
    final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final parsedDates = availableDates
        .map((d) => DateTime.tryParse(d) ?? parsedDate)
        .toList();
    return NdviImage(
      areaId: areaId,
      date: parsedDate,
      imageBase64: imageBase64,
      imageCachePath: imagePath,
      source: source,
      cloudCoverage: cloudCoverage,
      availableDates: parsedDates,
      cachedAt: DateTime.tryParse(cachedAt) ?? DateTime.now(),
    );
  }
}
