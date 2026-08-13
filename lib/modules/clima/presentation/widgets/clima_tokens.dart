import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

// ─── Design Tokens — Módulo Clima (theme-aware) ─────────────────────────────

/// Cores do módulo Clima derivadas do tema ativo (Verde/Azul/Black).
extension ClimaTheme on BuildContext {
  Color get climaBg => premiumBackground;

  Color get climaCard => premiumSurface;

  Color get climaTint => Theme.of(this).colorScheme.primary;

  Color get climaTextPrimary => premiumTextPrimary;

  Color get climaTextSecondary => premiumTextSecondary;

  Color get climaTextTertiary => premiumTextTertiary;

  Color get climaDivider => premiumHairline;

  Color get climaShadow => Colors.black.withValues(
        alpha: Theme.of(this).brightness == Brightness.dark ? 0.28 : 0.06,
      );

  Color get climaSegmentTrack => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF242426)
      : const Color(0xFFE5E5EA);
}

/// Texto sobre cards com gradiente (hero, horário, semanal).
const kClimaOnGradientText = Colors.white;
const kClimaOnGradientTextMuted = Color(0xD9FFFFFF);
const kClimaOnGradientAccent = Color(0xFFBFE9FF);

// ─── Helpers compartilhados ───────────────────────────────────────────────────

/// Decoração padrão dos cards iOS do módulo clima.
BoxDecoration climaCardDecoration(BuildContext context) => BoxDecoration(
      color: context.climaCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: context.climaShadow,
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    );

/// Gradiente sutil do card principal conforme condição meteorológica.
LinearGradient climaWeatherGradient(String condicaoCodigo) {
  final isDay = condicaoCodigo.endsWith('d');
  final base = condicaoCodigo.replaceAll(RegExp(r'[dn]$'), '');
  return switch (base) {
    '01' => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDay
            ? [const Color(0xFF5AC8FA), const Color(0xFF007AFF)]
            : [const Color(0xFF5856D6), const Color(0xFF1C1C3A)],
      ),
    '02' || '03' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8E8E93), Color(0xFF636366)],
      ),
    '04' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFAEAEB2), Color(0xFF48484A)],
      ),
    '09' || '10' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
      ),
    '11' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5856D6), Color(0xFF2C2C54)],
      ),
    '13' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64D2FF), Color(0xFF0A84FF)],
      ),
    '50' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFAEAEB2), Color(0xFF8E8E93)],
      ),
    _ => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34C759), Color(0xFF248A3D)],
      ),
  };
}

/// Decoração com gradiente por condição — hero, horário ou semanal.
BoxDecoration climaGradientCardDecoration(
  BuildContext context,
  String condicaoCodigo, {
  double radius = 20,
  Offset shadowOffset = const Offset(0, 8),
  double shadowBlur = 24,
}) =>
    BoxDecoration(
      gradient: climaWeatherGradient(condicaoCodigo),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: context.climaShadow,
          offset: shadowOffset,
          blurRadius: shadowBlur,
        ),
      ],
    );

/// Decoração do card principal com gradiente + sombra.
BoxDecoration climaHeroCardDecoration(
  BuildContext context,
  String condicaoCodigo,
) =>
    climaGradientCardDecoration(context, condicaoCodigo);

/// Cards compactos do carrossel horário.
BoxDecoration climaHourlyCardDecoration(
  BuildContext context,
  String condicaoCodigo,
) =>
    climaGradientCardDecoration(
      context,
      condicaoCodigo,
      radius: 16,
      shadowOffset: const Offset(0, 4),
      shadowBlur: 10,
    );

/// Cards diários da previsão semanal.
BoxDecoration climaWeeklyCardDecoration(
  BuildContext context,
  String condicaoCodigo,
) =>
    climaGradientCardDecoration(
      context,
      condicaoCodigo,
      radius: 20,
      shadowOffset: const Offset(0, 6),
      shadowBlur: 16,
    );

/// Converte o código de ícone da OpenWeatherMap em emoji.
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

String climaTempStr(double celsius, ClimaUnidade unit) {
  if (unit == ClimaUnidade.fahrenheit) {
    return '${(celsius * 9 / 5 + 32).round()}°F';
  }
  return '${celsius.round()}°C';
}

String climaTempShort(double celsius, ClimaUnidade unit) {
  if (unit == ClimaUnidade.fahrenheit) {
    return '${(celsius * 9 / 5 + 32).round()}°';
  }
  return '${celsius.round()}°';
}

double climaTempValue(double celsius, ClimaUnidade unit) =>
    unit == ClimaUnidade.fahrenheit ? celsius * 9 / 5 + 32 : celsius;
