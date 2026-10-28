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

    test('ignora chave reservada _captions', () {
      const raw =
          '{"daninhas":["media/a.jpg"],"_captions":{"media/a.jpg":"Broto novos"}}';
      expect(parseFotosCategoriasJson(raw), ['media/a.jpg']);
    });
  });

  group('parseFotosCategoriasByCategory', () {
    test('não hidrata _captions como categoria', () {
      const raw =
          '{"daninhas":["media/a.jpg"],"_captions":{"media/a.jpg":"Broto"}}';
      expect(parseFotosCategoriasByCategory(raw), {
        'daninhas': ['media/a.jpg'],
      });
    });
  });

  group('parseFotosCaptions', () {
    test('lê legendas keyed por path', () {
      const raw =
          '{"daninhas":["media/a.jpg"],"_captions":{"media/a.jpg":"Broto novos"}}';
      expect(parseFotosCaptions(raw), {'media/a.jpg': 'Broto novos'});
      expect(captionForPath(raw, 'media/a.jpg'), 'Broto novos');
      expect(captionForPath(raw, 'media/missing.jpg'), isNull);
    });

    test('retorna vazio no JSON legado só com lists', () {
      const raw = '{"daninhas":["media/a.jpg"]}';
      expect(parseFotosCaptions(raw), isEmpty);
    });

    test('recorta legenda acima do teto', () {
      final long = 'x' * 200;
      final raw =
          '{"daninhas":["media/a.jpg"],"_captions":{"media/a.jpg":"$long"}}';
      expect(
        parseFotosCaptions(raw)['media/a.jpg']?.length,
        kOccurrencePhotoCaptionMaxLength,
      );
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

    test('reescreve chaves de _captions junto com os paths', () {
      const raw =
          '{"daninhas":["/var/mobile/media/img_old.jpg"],"_captions":{"/var/mobile/media/img_old.jpg":"Broto novos"}}';
      final encoded = encodeFotosCategoriasJson(
        raw,
        (path) => path.contains('img_old.jpg') ? 'media/img_old.jpg' : path,
      );
      expect(encoded, isNotNull);
      final decoded = parseFotosCaptions(encoded);
      expect(decoded, {'media/img_old.jpg': 'Broto novos'});
      expect(parseFotosCategoriasJson(encoded), ['media/img_old.jpg']);
    });
  });

  group('encodeFotosCategoriasWithCaptions', () {
    test('omite _captions quando não há legendas', () {
      final encoded = encodeFotosCategoriasWithCaptions(
        {
          'daninhas': ['media/a.jpg'],
        },
        const {},
      );
      expect(encoded, '{"daninhas":["media/a.jpg"]}');
    });

    test('inclui só legendas de paths conhecidos', () {
      final encoded = encodeFotosCategoriasWithCaptions(
        {
          'daninhas': ['media/a.jpg'],
        },
        {
          'media/a.jpg': '  Broto novos  ',
          'media/orphaned.jpg': 'ignorada',
        },
      );
      expect(parseFotosCaptions(encoded), {'media/a.jpg': 'Broto novos'});
    });

    test('retorna null sem fotos', () {
      expect(
        encodeFotosCategoriasWithCaptions(const {}, {'a': 'b'}),
        isNull,
      );
    });
  });
}
