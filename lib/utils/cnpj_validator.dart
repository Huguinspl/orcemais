// lib/utils/cnpj_validator.dart
//
// Validação básica de CNPJ 🇧🇷.

class CnpjValidator {
  static bool isValid(String raw) {
    final numbers = raw.replaceAll(RegExp(r'\D'), '');

    if (numbers.length != 14) return false;

    // Rejeita sequências iguais (ex.: 00000000000000)
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return false;

    int calcDigit(String str, List<int> peso) {
      var sum = 0;
      for (var i = 0; i < peso.length; i++) {
        sum += int.parse(str[i]) * peso[i];
      }
      final mod = sum % 11;
      return (mod < 2) ? 0 : 11 - mod;
    }

    const peso1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const peso2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    final dig1 = calcDigit(numbers.substring(0, 12), peso1);
    final dig2 = calcDigit(numbers.substring(0, 12) + dig1.toString(), peso2);

    return numbers.endsWith('$dig1$dig2');
  }
}
