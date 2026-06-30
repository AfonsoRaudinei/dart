class QuickPhotoRecord {
  final String id;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final String? visitSessionId;
  final String type;
  final String? storagePath;
  final String? publicUrl;
  final int syncStatus;
  final String? publicationId;

  const QuickPhotoRecord({
    required this.id,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.visitSessionId,
    this.type = 'normal',
    this.storagePath,
    this.publicUrl,
    this.syncStatus = 1,
    this.publicationId,
  });

  factory QuickPhotoRecord.fromMap(Map<String, dynamic> map) {
    return QuickPhotoRecord(
      id: map['id'] as String,
      imagePath: map['local_path'] as String?,
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      visitSessionId: map['visit_session_id'] as String?,
      type: map['photo_type'] as String? ?? 'normal',
      storagePath: map['storage_path'] as String?,
      publicUrl: map['public_url'] as String?,
      syncStatus: map['sync_status'] as int? ?? 1,
    );
  }
}
