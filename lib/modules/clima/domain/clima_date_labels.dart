const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

const _meses = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

/// `Sáb`, `Dom`, `Seg`…
String climaDiaSemanaCurto(DateTime data) => _diasSemana[data.weekday % 7];

/// `Sáb 26/Set` — rótulo dos cards diários.
String climaDataDiaMes(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  return '${climaDiaSemanaCurto(data)} $dia/${_meses[data.month - 1]}';
}
