import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/data/quick_photo_repository.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/domain/quick_photo_record.dart';

void main() {
  group('QuickPhotoRepository.typeLabel', () {
    test('rotula foto normal', () {
      expect(
        QuickPhotoRepository.typeLabel(QuickPhotoType.normal.value),
        'Foto rápida',
      );
    });

    test('rotula inversão vegetal', () {
      expect(
        QuickPhotoRepository.typeLabel(QuickPhotoType.vegetalFilter.value),
        'Inversão vegetal',
      );
    });
  });

  group('filtro de fotos da visita', () {
    final photos = [
      QuickPhotoRecord(
        id: '1',
        imagePath: '/a.jpg',
        createdAt: DateTime.utc(2026, 6, 1),
        type: QuickPhotoType.normal.value,
        visitSessionId: 'session-1',
      ),
      QuickPhotoRecord(
        id: '2',
        imagePath: '/b.jpg',
        createdAt: DateTime.utc(2026, 6, 2),
        type: QuickPhotoType.vegetalFilter.value,
      ),
    ];

    test('filtra por tipo normal', () {
      final filtered = photos
          .where((photo) => photo.type == QuickPhotoType.normal.value)
          .toList();
      expect(filtered, hasLength(1));
      expect(filtered.first.id, '1');
    });

    test('filtra órfãs sem visit_session_id', () {
      final filtered = photos
          .where((photo) => photo.visitSessionId?.isNotEmpty != true)
          .toList();
      expect(filtered, hasLength(1));
      expect(filtered.first.id, '2');
    });
  });
}
