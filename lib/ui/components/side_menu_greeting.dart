/// Saudação humana do cabeçalho do menu lateral.
///
/// Lógica pura (sem Flutter) para ser testada: período do dia, primeiro
/// nome em formato de pessoa (não "RAUDINEI") e linha de contexto da agenda.
library;

/// "Bom dia" até 11h59, "Boa tarde" até 17h59 e "Boa noite" depois.
String greetingPeriod(DateTime now) {
  if (now.hour < 12) return 'Bom dia';
  if (now.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Primeiro nome com inicial maiúscula ("RAUDINEI Afonso" → "Raudinei").
/// Retorna `null` quando não há nome utilizável.
String? firstNameOf(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final first = trimmed.split(RegExp(r'\s+')).first;
  if (first.isEmpty) return null;
  return first[0].toUpperCase() + first.substring(1).toLowerCase();
}

/// "Bom dia, Raudinei" — sem nome, só o período ("Bom dia").
String greetingLine(DateTime now, String? fullName) {
  final period = greetingPeriod(now);
  final name = firstNameOf(fullName);
  return name == null ? period : '$period, $name';
}

/// Linha de contexto sob a saudação, conforme as visitas pendentes de hoje.
String visitsContextLine(int pendingToday) {
  if (pendingToday <= 0) return 'Nenhuma visita pendente hoje';
  if (pendingToday == 1) return 'Você tem 1 visita hoje';
  return 'Você tem $pendingToday visitas hoje';
}

/// Foto do cabeçalho do menu: alterna por dia (par = plantio, ímpar = colheita).
String menuHeaderPhoto(DateTime now) => now.day.isEven
    ? 'assets/images/menu/header_plantio.jpg'
    : 'assets/images/menu/header_colheita.jpg';
