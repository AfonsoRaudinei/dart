import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_drawing_field_writer.dart';

/// Provider neutro de IDrawingFieldWriter.
/// A implementacao concreta deve ser registrada via ProviderScope.overrides.
final iDrawingFieldWriterProvider = Provider<IDrawingFieldWriter>((ref) {
  throw UnimplementedError(
    'iDrawingFieldWriterProvider: registrar adapter no ProviderScope.',
  );
});
