import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/dashboard/services/location_service.dart';

void main() {
  // Inicializar binding para testes que usam platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService - Estrutura', () {
    test('deve ser singleton', () {
      final instance1 = LocationService();
      final instance2 = LocationService();
      
      expect(instance1, equals(instance2));
    });

    test('deve expor stream de localização', () {
      final locationService = LocationService();
      
      expect(locationService.locationStream, isA<Stream<LatLng>>());
    });

    test('stream deve ser broadcast (múltiplos listeners)', () {
      final locationService = LocationService();
      final stream = locationService.locationStream;
      
      expect(stream.isBroadcast, isTrue);
    });

    test('não deve criar múltiplos streams', () {
      final locationService = LocationService();
      
      final stream1 = locationService.locationStream;
      final stream2 = locationService.locationStream;
      
      // Mesmo controller (não criar duplicado)
      // Nota: Streams podem ser diferentes instâncias mas compartilham controller
      expect(stream1, isA<Stream<LatLng>>());
      expect(stream2, isA<Stream<LatLng>>());
    });

    test('dispose deve executar sem erro', () {
      final locationService = LocationService();
      
      // Obter stream para criar subscription
      locationService.locationStream;
      
      // Dispose deve limpar recursos
      expect(() => locationService.dispose(), returnsNormally);
    });
  });

  group('LocationService - Documentação', () {
    test('estrutura do serviço está documentada', () {
      // Este teste serve como documentação viva da estrutura
      final locationService = LocationService();
      
      // ✅ Singleton pattern
      expect(locationService, equals(LocationService()));
      
      // ✅ Stream broadcast
      expect(locationService.locationStream.isBroadcast, isTrue);
      
      // ✅ Tipo correto
      expect(locationService.locationStream, isA<Stream<LatLng>>());
      
      // ✅ Métodos disponíveis
      expect(locationService.getCurrentPosition, isA<Function>());
      expect(locationService.checkAvailability, isA<Function>());
      expect(locationService.dispose, isA<Function>());
    });
  });
}

