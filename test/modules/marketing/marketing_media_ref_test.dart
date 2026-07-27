import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_media_ref.dart';

void main() {
  group('MarketingMediaRef', () {
    test('detecta URL remota', () {
      expect(
        MarketingMediaRef.isRemoteUrl('https://cdn.example/foto.jpg'),
        isTrue,
      );
      expect(
        MarketingMediaRef.isRemoteUrl('http://cdn.example/foto.jpg'),
        isTrue,
      );
      expect(MarketingMediaRef.isLocalPath('https://cdn.example/a.jpg'), isFalse);
    });

    test('detecta path local absoluto', () {
      const path = '/var/mobile/Documents/media/marketing/mkt_1.jpg';
      expect(MarketingMediaRef.isLocalPath(path), isTrue);
      expect(MarketingMediaRef.isRemoteUrl(path), isFalse);
      expect(MarketingMediaRef.toFilePath(path), path);
    });

    test('normaliza file://', () {
      const uri = 'file:///tmp/media/marketing/mkt_1.jpg';
      expect(MarketingMediaRef.isLocalPath(uri), isTrue);
      expect(
        MarketingMediaRef.toFilePath(uri),
        '/tmp/media/marketing/mkt_1.jpg',
      );
    });

    test('null/vazio não é local nem remoto', () {
      expect(MarketingMediaRef.isLocalPath(null), isFalse);
      expect(MarketingMediaRef.isRemoteUrl(null), isFalse);
      expect(MarketingMediaRef.isLocalPath(''), isFalse);
      expect(MarketingMediaRef.toFilePath(null), isNull);
    });
  });
}
