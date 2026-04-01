// lib/core/contracts/i_field_lookup_geofence_provider.dart
//
// Provider neutro de IFieldLookup para uso exclusivo do geofence_controller.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
//
// Separado de iFieldLookupProvider (drawing/) por ter fonte de dados diferente:
// drawing/ → DrawingLocalStore; geofence → FieldRepository (SQLite/Supabase).
// ADR-024

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_field_lookup.dart';

final iFieldLookupGeofenceProvider = Provider<IFieldLookup>((ref) {
  throw UnimplementedError(
    'iFieldLookupGeofenceProvider: registrar FieldLookupGeofenceAdapter no '
    'ProviderScope (veja main.dart e ADR-024)',
  );
});
