import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contratos do fix MapMarkSheet + foto (nested sheet + teclado + upload null).
void main() {
  group('FotoPickerWidget marketing photo fix contracts', () {
    test('unfocus teclado antes de abrir seletor de foto', () {
      final source = File(
        'lib/modules/marketing/presentation/widgets/foto_picker_widget.dart',
      ).readAsStringSync();

      expect(source.contains('FocusManager.instance.primaryFocus?.unfocus()'), isTrue);
    });

    test('includeVegetalInversion captura URL após showSoloFortePhotoPicker', () {
      final source = File(
        'lib/modules/marketing/presentation/widgets/foto_picker_widget.dart',
      ).readAsStringSync();

      expect(source.contains('uploadedUrl'), isTrue);
      expect(source.contains('url = uploadedUrl'), isTrue);
      expect(source.contains('useRootNavigator: true'), isTrue);
    });

    test('MarketingPhotoService abre origem no root navigator', () {
      final source = File(
        'lib/modules/marketing/data/services/marketing_photo_service.dart',
      ).readAsStringSync();

      expect(source.contains('useRootNavigator: true'), isTrue);
      expect(
        source.contains('Não foi possível enviar a foto. Tente novamente.'),
        isTrue,
      );
    });

    test('showSoloForteSheet repassa useRootNavigator ao modal', () {
      final sheet = File(
        'lib/core/ui/sheets/soloforte_sheet.dart',
      ).readAsStringSync();
      final picker = File(
        'lib/core/widgets/photo/soloforte_photo_picker_sheet.dart',
      ).readAsStringSync();

      expect(sheet.contains('bool useRootNavigator = false'), isTrue);
      expect(sheet.contains('useRootNavigator: useRootNavigator'), isTrue);
      expect(picker.contains('bool useRootNavigator = false'), isTrue);
    });
  });
}
