import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_photo_paths.dart';

Occurrence _occurrence({
  String? photoPath,
  String? fotosCategoriasJson,
}) {
  final now = DateTime.utc(2026, 9, 18, 8, 58);
  return Occurrence(
    id: 'occ-1',
    type: 'Média',
    description: 'teste',
    photoPath: photoPath,
    createdAt: now,
    updatedAt: now,
    fotosCategoriasJson: fotosCategoriasJson,
  );
}

void main() {
  group('parseFotosCategoriasJson', () {
    test('retorna lista plana de paths', () {
      const raw = '{"amostraSolo":["media/a.jpg"],"insetos":["media/b.jpg"]}';
      expect(parseFotosCategoriasJson(raw), ['media/a.jpg', 'media/b.jpg']);
    });

    test('retorna vazio para json inválido', () {
      expect(parseFotosCategoriasJson(null), isEmpty);
      expect(parseFotosCategoriasJson('{}'), isEmpty);
      expect(parseFotosCategoriasJson('not-json'), isEmpty);
    });
  });

  group('allPhotoPaths', () {
    test('usa fotosCategoriasJson quando presente', () {
      final occurrence = _occurrence(
        photoPath: 'media/cover.jpg',
        fotosCategoriasJson: '{"amostraSolo":["media/a.jpg"]}',
      );
      expect(allPhotoPaths(occurrence), ['media/a.jpg', 'media/cover.jpg']);
    });

    test('faz fallback para photoPath quando json vazio', () {
      final occurrence = _occurrence(photoPath: 'media/legacy.jpg');
      expect(allPhotoPaths(occurrence), ['media/legacy.jpg']);
    });

    test('retorna vazio sem fotos', () {
      expect(allPhotoPaths(_occurrence()), isEmpty);
    });
  });

  group('coverPhotoPath', () {
    test('retorna primeiro path disponível', () {
      final occurrence = _occurrence(
        photoPath: 'media/cover.jpg',
        fotosCategoriasJson: '{"amostraSolo":["media/a.jpg"]}',
      );
      expect(coverPhotoPath(occurrence), 'media/a.jpg');
    });
  });

  group('encodeFotosCategoriasJson', () {
    test('normaliza paths com toStoredPath', () {
      const raw =
          '{"amostraSolo":["/var/mobile/media/img_old.jpg","media/new.jpg"]}';
      final encoded = encodeFotosCategoriasJson(
        raw,
        (path) => path.contains('img_old.jpg') ? 'media/img_old.jpg' : path,
      );
      expect(encoded, contains('media/img_old.jpg'));
      expect(encoded, contains('media/new.jpg'));
    });
  });
}
