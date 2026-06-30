import 'package:flutter/material.dart';

// ─── Design Tokens — Módulo Clima ─────────────────────────────────────────────

const kClimaBg = Color(0xFFF2F2F7);
const kClimaCard = Colors.white;
const kClimaTint = Color(0xFF34C759);
const kClimaTextPrimary = Color(0xFF000000);
const kClimaTextSecondary = Color(0xFF3C3C43);
const kClimaTextTertiary = Color(0xFF8E8E93);
const kClimaDivider = Color(0xFFE5E5EA);
const kClimaShadow = Color.fromRGBO(0, 0, 0, 0.06);

// ─── Helpers compartilhados ───────────────────────────────────────────────────

/// Decoração padrão dos cards iOS do módulo clima.
BoxDecoration climaCardDecoration() => BoxDecoration(
      color: kClimaCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: kClimaShadow,
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    );

/// Converte o código de ícone da OpenWeatherMap em emoji.
/// Ex: '01d' → '☀️', '01n' → '🌙', '11d' → '⛈️'
String climaWeatherEmoji(String code) {
  final isDay = code.endsWith('d');
  final base = code.replaceAll(RegExp(r'[dn]$'), '');
  return switch (base) {
    '01' => isDay ? '☀️' : '🌙',
    '02' => '⛅',
    '03' => '🌥️',
    '04' => '☁️',
    '09' => '🌧️',
    '10' => '🌦️',
    '11' => '⛈️',
    '13' => '❄️',
    '50' => '🌫️',
    _ => '🌡️',
  };
}

// ─── Unidade de temperatura ───────────────────────────────────────────────────

enum ClimaUnidade { celsius, fahrenheit }

/// Temperatura com símbolo de unidade. Ex: '23°C' ou '73°F'
String climaTempStr(double celsius, ClimaUnidade unit) {
  if (unit == ClimaUnidade.fahrenheit) {
    return '${(celsius * 9 / 5 + 32).round()}°F';
  }
  return '${celsius.round()}°C';
}

/// Temperatura curta sem abreviação. Ex: '23°' ou '73°'
String climaTempShort(double celsius, ClimaUnidade unit) {
  if (unit == ClimaUnidade.fahrenheit) {
    return '${(celsius * 9 / 5 + 32).round()}°';
  }
  return '${celsius.round()}°';
}

/// Valor numérico convertido — para uso em gráficos.
double climaTempValue(double celsius, ClimaUnidade unit) =>
    unit == ClimaUnidade.fahrenheit ? celsius * 9 / 5 + 32 : celsius;
