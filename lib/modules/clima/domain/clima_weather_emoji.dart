/// Converte o código de ícone (OWM) em emoji para texto e cards.
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
