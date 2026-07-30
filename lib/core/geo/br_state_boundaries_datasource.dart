import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../utils/app_logger.dart';

/// Carrega malhas UF do IBGE e converte para polígonos do flutter_map.
class BrStateBoundariesDatasource {
  BrStateBoundariesDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Polygon>> fetchStatePolygons() async {
    final response = await _client.get(Uri.parse(MapConfig.ibgeStateBoundariesUrl));
    if (response.statusCode != 200) {
      AppLogger.warning(
        'Malha UF IBGE indisponível',
        tag: 'MapBoundaries',
        error: 'HTTP ${response.statusCode}',
      );
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) return const [];

    final polygons = <Polygon>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final geometry = item['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      polygons.addAll(_geometryToPolygons(geometry));
    }
    return polygons;
  }
}

List<Polygon> _geometryToPolygons(Map<String, dynamic> geometry) {
  final type = geometry['type'] as String?;
  final coordinates = geometry['coordinates'];
  if (type == null || coordinates is! List<dynamic>) return const [];

  const borderColor = Color(0xCCFFFFFF);
  const fillColor = Color(0x14FFFFFF);

  return switch (type) {
    'Polygon' => [
      Polygon(
        points: _ringToLatLng(coordinates.first as List<dynamic>),
        borderColor: borderColor,
        borderStrokeWidth: 1.5,
        color: fillColor,
      ),
    ],
    'MultiPolygon' => [
      for (final polygon in coordinates)
        if (polygon is List<dynamic> && polygon.isNotEmpty)
          Polygon(
            points: _ringToLatLng(polygon.first as List<dynamic>),
            borderColor: borderColor,
            borderStrokeWidth: 1.5,
            color: fillColor,
          ),
    ],
    _ => const [],
  };
}

List<LatLng> _ringToLatLng(List<dynamic> ring) {
  return ring
      .whereType<List<dynamic>>()
      .map((pair) {
        if (pair.length < 2) return null;
        final lng = (pair[0] as num).toDouble();
        final lat = (pair[1] as num).toDouble();
        return LatLng(lat, lng);
      })
      .whereType<LatLng>()
      .toList(growable: false);
}
