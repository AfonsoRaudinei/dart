enum PasswordStrength { weak, medium, strong }

class AuthValidators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório';
    if (value.trim().length < 3) return 'Mínimo de 3 caracteres';

    // Não aceitar apenas números isolados (ex: "123")
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
    if (!hasLetters) return 'Nome deve conter letras';

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email é obrigatório';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Telefone é obrigatório';

    // Rejeitar letras
    if (value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Telefone deve conter apenas números';
    }

    // Remove caracteres não numéricos
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 10) return 'Mínimo de 10 dígitos (DDD + Número)';
    if (digits.length > 11) return 'Máximo de 11 dígitos';

    // DDDs válidos do Brasil: 11–99 (excluindo faixas inexistentes)
    final ddd = int.tryParse(digits.substring(0, 2)) ?? 0;
    const dddsValidos = {
      11, 12, 13, 14, 15, 16, 17, 18, 19, // SP
      21, 22, 24, // RJ
      27, 28, // ES
      31, 32, 33, 34, 35, 37, 38, // MG
      41, 42, 43, 44, 45, 46, // PR
      47, 48, 49, // SC
      51, 53, 54, 55, // RS
      61, // DF
      62, 64, // GO
      63, // TO
      65, 66, // MT
      67, // MS
      68, // AC
      69, // RO
      71, 73, 74, 75, 77, // BA
      79, // SE
      81, 82, 83, 84, 85, 86, 87, 88, 89, // NE
      91, 92, 93, 94, 95, 96, 97, 98, 99, // N
    };
    if (!dddsValidos.contains(ddd)) {
      return 'DDD inválido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    if (value.contains(' ')) return 'Senha não pode conter espaços';
    if (value.length < 8) return 'Mínimo de 8 caracteres';

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigits = RegExp(r'[0-9]').hasMatch(value);

    if (!hasUpperCase) return 'Deve conter uma letra maiúscula';
    if (!hasLowerCase) return 'Deve conter uma letra minúscula';
    if (!hasDigits) return 'Deve conter um número';

    return null;
  }

  static PasswordStrength evaluatePasswordStrength(String value) {
    if (value.isEmpty) return PasswordStrength.weak;

    int score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value)) score++;

    // Penalizar sequências óbvias
    final weakSequences = ['123456', 'password', 'qwerty', '000000', 'senha'];
    for (var seq in weakSequences) {
      if (value.toLowerCase().contains(seq)) return PasswordStrength.weak;
    }

    if (score < 3) return PasswordStrength.weak;
    if (score < 5) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}
