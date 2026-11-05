import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/data/report_share_link_service.dart';

void main() {
  group('ReportShareLinkService', () {
    test('storagePathForUser usa userId e token.html', () {
      expect(
        ReportShareLinkService.storagePathForUser(
          userId: 'user-abc',
          token: 'tok-1',
        ),
        'user-abc/tok-1.html',
      );
    });

    test('ensureMobileReadyHtml injeta viewport quando ausente', () {
      const raw = '<html><head></head><body><p>Rel</p></body></html>';
      final out = ReportShareLinkService.ensureMobileReadyHtml(raw);
      expect(out.toLowerCase(), contains('viewport'));
      expect(out, contains('width=device-width'));
    });

    test('ensureMobileReadyHtml adiciona stub PDF desabilitado', () {
      const raw =
          '<!DOCTYPE html><html><head><meta name="viewport" content="width=1"></head><body></body></html>';
      final out = ReportShareLinkService.ensureMobileReadyHtml(raw);
      expect(out, contains('sf-share-pdf-stub'));
      expect(out, contains('Gerar PDF (em breve)'));
    });

    test('ensureMobileReadyHtml envolve fragmento sem html', () {
      const raw = '<p>Só corpo</p>';
      final out = ReportShareLinkService.ensureMobileReadyHtml(raw);
      expect(out.toLowerCase(), contains('<html'));
      expect(out, contains('Só corpo'));
    });
  });
}
