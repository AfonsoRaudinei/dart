import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:soloforte_app/core/permissions/i_permission_service.dart';
import 'package:soloforte_app/core/permissions/permission_service_impl.dart';

part 'permission_provider.g.dart';

@riverpod
IPermissionService permissionService(PermissionServiceRef ref) {
  return PermissionServiceImpl();
}

@riverpod
Future<LocationPermission> locationPermission(LocationPermissionRef ref) async {
  return await Geolocator.checkPermission();
}
