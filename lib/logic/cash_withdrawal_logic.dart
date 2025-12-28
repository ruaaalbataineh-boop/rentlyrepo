class CashWithdrawalLogic {
  final double currentBalance;

  CashWithdrawalLogic({required this.currentBalance});

  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter amount';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter valid amount';
    }

    if (amount < 10) {
      return 'Minimum withdrawal is \$10';
    }

    if (amount > currentBalance) {
      return 'Amount exceeds balance';
    }

    if (amount > 1000) {
      return 'Daily limit is \$1,000';
    }

    final decimalPart = value.split('.');
    if (decimalPart.length > 1 && decimalPart[1].length > 2) {
      return 'Maximum 2 decimal places';
    }

    return null;
  }

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter full name';
    }

    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'Name must contain only letters and spaces';
    }

    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Please enter first and last name';
    }

    return null;
  }

  String? validateNationalID(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter national ID';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'National ID must contain only digits';
    }

    if (value.length != 10) {
      return 'National ID must be 10 digits';
    }

    return null;
  }

  String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter date of birth';
    }

    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
      return 'Format: DD/MM/YYYY';
    }

    final parts = value.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final birthDate = DateTime(year, month, day);
    final age = DateTime.now().year - birthDate.year;

    if (age < 18) {
      return 'Must be 18 years or older';
    }

    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }

    final phone = value.replaceAll(RegExp(r'[^\d]'), '');

    if (phone.length != 10) {
      return 'Phone must be 10 digits';
    }

    if (!phone.startsWith('07')) {
      return 'Invalid phone number';
    }

    return null;
  }

  String generateWithdrawalCode() {
    return 'RTL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }
}
