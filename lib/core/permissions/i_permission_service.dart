enum PermissionType { camera, photoLibrary, locationWhenInUse, locationAlways }

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted, // iOS only
}

abstract class IPermissionService {
  Future<PermissionStatus> request(PermissionType type);
  Future<PermissionStatus> check(PermissionType type);
  Future<void> openSettings();
}
