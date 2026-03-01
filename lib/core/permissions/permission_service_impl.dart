import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:soloforte_app/core/permissions/i_permission_service.dart';

class PermissionServiceImpl implements IPermissionService {
  @override
  Future<PermissionStatus> request(PermissionType type) async {
    final phType = _mapTypeToPhType(type);

    if (type == PermissionType.locationAlways) {
      final inUseStatus = await ph.Permission.locationWhenInUse.status;
      if (!inUseStatus.isGranted) {
        return PermissionStatus.denied;
      }
    }

    final phStatus = await phType.request();
    return _mapPhStatusToStatus(phStatus);
  }

  @override
  Future<PermissionStatus> check(PermissionType type) async {
    final phType = _mapTypeToPhType(type);
    final phStatus = await phType.status;
    return _mapPhStatusToStatus(phStatus);
  }

  @override
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  ph.Permission _mapTypeToPhType(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return ph.Permission.camera;
      case PermissionType.photoLibrary:
        return ph.Permission.photos;
      case PermissionType.locationWhenInUse:
        return ph.Permission.locationWhenInUse;
      case PermissionType.locationAlways:
        return ph.Permission.locationAlways;
    }
  }

  PermissionStatus _mapPhStatusToStatus(ph.PermissionStatus phStatus) {
    switch (phStatus) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.provisional:
      case ph.PermissionStatus.limited:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
    }
  }
}
