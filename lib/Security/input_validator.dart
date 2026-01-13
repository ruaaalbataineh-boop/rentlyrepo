class InputValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(phone);
  }

  static bool hasNoMaliciousCode(String input) {
    List<String> maliciousPatterns = [
      '<script', 'javascript:', 'onload=', 'onerror=',
      'eval(', 'document.cookie', 'alert(', 'confirm(', 'prompt('
    ];
    
    String lowerInput = input.toLowerCase();
    return !maliciousPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }
}
