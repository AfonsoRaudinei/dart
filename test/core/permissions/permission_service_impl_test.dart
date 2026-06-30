import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as phpi;
import 'package:soloforte_app/core/permissions/i_permission_service.dart';
import 'package:soloforte_app/core/permissions/permission_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IPermissionService permissionService;
  late MethodChannel channel;

  // Variável para controlarmos a resposta no mock
  ph.PermissionStatus mockStatus = ph.PermissionStatus.granted;

  setUp(() {
    permissionService = PermissionServiceImpl();
    channel = const MethodChannel('flutter.baseflow.com/permissions/methods');

    // Mockando as chamadas do MethodChannel do permission_handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return phpi.PermissionStatusValue(mockStatus).value;
          }
          if (methodCall.method == 'requestPermissions') {
            // requestPermissions retorna um mapa {int: int} correspondente ao map de <Permission, PermissionStatus>
            final int permissionValue =
                (methodCall.arguments as List)[0] as int;
            return {
              permissionValue: phpi.PermissionStatusValue(mockStatus).value,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PermissionServiceImpl -', () {
    test('check camera permission - granted', () async {
      mockStatus = ph.PermissionStatus.granted;
      final status = await permissionService.check(PermissionType.camera);
      expect(status, PermissionStatus.granted);
    });

    test('check location permission - denied', () async {
      // Mockando a não autorização da localização
      mockStatus = ph.PermissionStatus.denied;
      final status = await permissionService.check(
        PermissionType.locationWhenInUse,
      );
      expect(status, PermissionStatus.denied);
    });

    test('request photo library permission - permanently denied', () async {
      mockStatus = ph.PermissionStatus.permanentlyDenied;
      final status = await permissionService.request(
        PermissionType.photoLibrary,
      );
      expect(status, PermissionStatus.permanentlyDenied);
    });

    test(
      'request locationAlways require locationWhenInUse to be granted first',
      () async {
        // Configuramos para negar porque estamos testando quando WhenInUse é negada
        mockStatus = ph.PermissionStatus.denied;

        final status = await permissionService.request(
          PermissionType.locationAlways,
        );

        // Conforme a regra de negócio do arquivo permission_service_impl.dart
        // Se a resposta do "locationWhenInUse.status" (que o mock devolve como negado) for negada, ele já retorna PermissionStatus.denied
        expect(status, PermissionStatus.denied);
      },
    );
  });
}
