import '../../../../core/contracts/i_visit_photo_read.dart';
import '../data/quick_photo_repository.dart';

class QuickPhotoReadAdapter implements IVisitPhotoRead {
  const QuickPhotoReadAdapter(this._repository);

  final QuickPhotoRepository _repository;

  @override
  Future<List<VisitPhotoSummary>> getBySessionId(String sessionId) async {
    final photos = await _repository.getByVisitSessionId(sessionId);
    return photos
        .where((photo) => photo.imagePath?.isNotEmpty == true)
        .map(
          (photo) => VisitPhotoSummary(
            id: photo.id,
            localPath: photo.imagePath!,
            createdAt: photo.createdAt,
            lat: photo.latitude,
            lng: photo.longitude,
            type: photo.type,
          ),
        )
        .toList();
  }
}
