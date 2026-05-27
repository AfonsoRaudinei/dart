class QuickPhotoRecord {
  final String id;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final String? publicationId;

  const QuickPhotoRecord({
    required this.id,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.publicationId,
  });
}
