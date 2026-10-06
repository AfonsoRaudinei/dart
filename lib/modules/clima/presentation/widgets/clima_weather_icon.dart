import 'package:flutter/material.dart';

/// Ícone de linha para o código de condição (OWM), usado nos cards premium.
///
/// Complementa `climaWeatherEmoji`, que segue valendo para texto do WhatsApp.
IconData climaWeatherIcon(String code) {
  final isDay = code.endsWith('d');
  final base = code.replaceAll(RegExp(r'[dn]$'), '');
  return switch (base) {
    '01' => isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
    '02' => isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
    '03' => Icons.cloud_queue_rounded,
    '04' => Icons.cloud_rounded,
    '09' => Icons.grain_rounded,
    '10' => Icons.water_drop_rounded,
    '11' => Icons.thunderstorm_rounded,
    '13' => Icons.ac_unit_rounded,
    '50' => Icons.foggy,
    _ => Icons.thermostat_rounded,
  };
}
