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
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Telefone é obrigatório';

    // Remove caracteres não numéricos
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 10) return 'Mínimo de 10 dígitos (DDD + Número)';

    // Não aceitar letras (já feito pelo inputType, mas reforçando)
    if (value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Telefone deve conter apenas números';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
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
    if (RegExp(r'[!@#\$&*~]').hasMatch(value)) score++;

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
