import 'package:latlong2/latlong.dart';

/// Contrato de acesso à localização atual do usuário.
/// Zona neutra em core/contracts/ — acessível por todos os bounded contexts.
/// Implementado por: dashboard/infra/location_lookup_adapter.dart
/// Consumido por: clima/presentation/providers/clima_providers.dart
/// Registrado via ProviderScope.overrides em main.dart.
abstract interface class IUserLocationLookup {
  /// Retorna a última posição conhecida do usuário.
  /// null = posição ainda não obtida (mapa não inicializado ou GPS indisponível).
  LatLng? getUserLatLng();
}
