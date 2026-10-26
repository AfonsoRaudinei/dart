/// Utilidades para texto de localização "Município - UF".
abstract final class MunicipioUf {
  static const Set<String> ufs = {
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  };

  static final RegExp _afterPunctuation = RegExp(r'[,\-–/]\s*([A-Za-z]{2})$');
  static final RegExp _afterSpaceUpper = RegExp(r'\s([A-Z]{2})$');

  /// `true` quando o texto já termina com uma sigla de UF válida
  /// ("Palmas - TO", "Palmas, to", "Palmas TO").
  static bool hasUf(String text) {
    final value = text.trim();
    final punctuation = _afterPunctuation.firstMatch(value)?.group(1);
    if (punctuation != null && ufs.contains(punctuation.toUpperCase())) {
      return true;
    }
    final spaced = _afterSpaceUpper.firstMatch(value)?.group(1);
    return spaced != null && ufs.contains(spaced);
  }

  /// "Palmas" + "TO" → "Palmas - TO". Sem UF devolve [municipio] limpo.
  static String compose(String municipio, String? uf) {
    final city = municipio.trim();
    final sigla = uf?.trim().toUpperCase();
    if (city.isEmpty || sigla == null || !ufs.contains(sigla)) return city;
    if (hasUf(city)) return city;
    return '$city - $sigla';
  }
}
