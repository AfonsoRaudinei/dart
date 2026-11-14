import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/session/local_session_identity.dart';
import 'linked_consultant_geometry.dart';
import 'producer_link_models.dart';

/// Lê desenhos do consultor e encaixa nos talhões da fazenda vinculada.
class ProducerLinkedDrawingLoader {
  ProducerLinkedDrawingLoader(this._client);

  final SupabaseClient _client;

  Future<ProducerLinkedClient> attach(ProducerLinkedClient client) async {
    if (!client.link.share.fields || client.farms.isEmpty) return client;
    try {
      final farmIds = client.farms
          .map((farm) => farm.id)
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      var drawings = await _loadLocal(client.link.clientId, farmIds);
      if (drawings.isEmpty) {
        drawings = await _loadRemote(client.link.clientId);
      }
      if (drawings.isEmpty) return client;
      return ProducerLinkedClient(
        link: client.link,
        name: client.name,
        phone: client.phone,
        email: client.email,
        city: client.city,
        state: client.state,
        farms: attachDrawingsToLinkedFarms(
          farms: client.farms,
          drawings: drawings,
        ),
        reports: client.reports,
        occurrences: client.occurrences,
      );
    } catch (_) {
      return client;
    }
  }

  Future<List<ProducerLinkedDrawing>> _loadLocal(
    String clientId,
    List<String> farmIds,
  ) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return const [];
    final db = await DatabaseHelper.instance.database;
    final farmClause = farmIds.isEmpty
        ? 'cliente_id = ?'
        : '(cliente_id = ? OR fazenda_id IN (${List.filled(farmIds.length, '?').join(', ')}))';
    final rows = await db.query(
      'drawings',
      columns: ['id', 'nome', 'area_ha', 'fazenda_id', 'geojson'],
      where: 'deleted_at IS NULL AND ativo = 1 AND tipo != ? AND $farmClause',
      whereArgs: ['teste', clientId, ...farmIds],
    );
    return preferOwnerDrawings(drawingsFromLocalRows(rows));
  }

  Future<List<ProducerLinkedDrawing>> _loadRemote(String clientId) async {
    final rows = await _client
        .from('drawings')
        .select('id, geometry, properties, deleted_at')
        .eq('properties->>cliente_id', clientId);
    return drawingsFromRemoteRows(rows);
  }

  /// A cópia `vinc_` só entra quando o desenho do consultor não está no aparelho.
  @visibleForTesting
  static List<ProducerLinkedDrawing> preferOwnerDrawings(
    List<ProducerLinkedDrawing> drawings,
  ) {
    const prefix = 'vinc_';
    final originals = drawings
        .map((drawing) => drawing.id)
        .where((id) => !id.startsWith(prefix))
        .toSet();
    final kept = <ProducerLinkedDrawing>[];
    for (final drawing in drawings) {
      if (!drawing.id.startsWith(prefix)) {
        kept.add(drawing);
        continue;
      }
      final sourceId = drawing.id.substring(prefix.length);
      if (originals.contains(sourceId)) continue;
      kept.add(
        ProducerLinkedDrawing(
          id: sourceId,
          name: drawing.name,
          areaHa: drawing.areaHa,
          farmId: drawing.farmId,
          groupName: drawing.groupName,
          geometryJson: drawing.geometryJson,
        ),
      );
    }
    return kept;
  }

  @visibleForTesting
  static List<ProducerLinkedDrawing> drawingsFromLocalRows(
    List<Map<String, Object?>> rows,
  ) {
    return rows
        .map((row) {
          final id = (row['id'] as String?)?.trim() ?? '';
          if (id.isEmpty) return null;
          final name = (row['nome'] as String?)?.trim() ?? '';
          return ProducerLinkedDrawing(
            id: id,
            name: name.isEmpty ? 'Talhão' : name,
            areaHa: _asDouble(row['area_ha']),
            farmId: (row['fazenda_id'] as String?)?.trim(),
            geometryJson: linkedFieldGeometryJson(row['geojson']),
          );
        })
        .whereType<ProducerLinkedDrawing>()
        .toList(growable: false);
  }

  @visibleForTesting
  static List<ProducerLinkedDrawing> drawingsFromRemoteRows(Object? rows) {
    final list = rows is List ? rows : const [];
    final drawings = <ProducerLinkedDrawing>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      if (row['deleted_at'] != null) continue;
      final id = (row['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) continue;
      final props = _decodeJsonMap(row['properties']);
      if (props == null) continue;
      final tipo = (props['tipo'] as String?)?.trim().toLowerCase();
      if (tipo == 'teste') continue;
      if (props['ativo'] == false) continue;
      final name = (props['nome'] as String?)?.trim() ?? '';
      drawings.add(
        ProducerLinkedDrawing(
          id: id,
          name: name.isEmpty ? 'Talhão' : name,
          areaHa: _asDouble(props['area_ha']),
          farmId: (props['fazenda_id'] as String?)?.trim(),
          groupName: (props['grupo'] as String?)?.trim(),
          geometryJson: linkedFieldGeometryJson(row['geometry']),
        ),
      );
    }
    return drawings;
  }

  static Map<String, dynamic>? _decodeJsonMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
