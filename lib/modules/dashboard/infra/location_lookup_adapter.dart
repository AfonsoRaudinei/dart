import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/contracts/i_user_location_lookup.dart';
import 'package:soloforte_app/modules/dashboard/controllers/location_controller.dart';

/// Implementação concreta de IUserLocationLookup.
/// Lê userPositionProvider (populado pelo LocationController do mapa).
/// Registrado via ProviderScope.overrides em main.dart.
/// NÃO importar este arquivo fora de dashboard/ ou da injeção de dependência.
class LocationLookupAdapter implements IUserLocationLookup {
  const LocationLookupAdapter(this._ref);

  final Ref _ref;

  @override
  LatLng? getUserLatLng() {
    return _ref.read(userPositionProvider);
  }
}
