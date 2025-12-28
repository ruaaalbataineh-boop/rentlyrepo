import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/withdrawal_logic.dart';

void main() {
  late CashWithdrawalLogic logic;

  setUp(() {
    logic = CashWithdrawalLogic(currentBalance: 1000);
  });

  group('Amount Validation', () {
    test('Empty amount', () {
      expect(logic.validateAmount(''), 'Please enter amount');
    });

    test('Null amount', () {
      expect(logic.validateAmount(null), 'Please enter amount');
    });

    test('Non numeric amount', () {
      expect(logic.validateAmount('abc'), 'Please enter valid amount');
    });

    test('Negative amount', () {
      expect(logic.validateAmount('-50'), 'Please enter valid amount');
    });

    test('Zero amount', () {
      expect(logic.validateAmount('0'), 'Please enter valid amount');
    });

    test('Below minimum amount', () {
      expect(logic.validateAmount('5'), 'Minimum withdrawal is \$10');
    });

    test('Above daily limit', () {
      expect(logic.validateAmount('1500'), 'Amount exceeds balance');
    });

    test('More than two decimal places', () {
      expect(logic.validateAmount('10.123'), 'Maximum 2 decimal places');
    });

    test('Valid integer amount', () {
      expect(logic.validateAmount('100'), null);
    });

    test('Valid decimal amount', () {
      expect(logic.validateAmount('99.99'), null);
    });
  });

  group('Full Name Validation', () {
    test('Empty name', () {
      expect(logic.validateFullName(''), 'Please enter full name');
    });

    test('Single word name', () {
      expect(logic.validateFullName('Ahmad'), 'Please enter first and last name');
    });

    test('Name with numbers', () {
      expect(logic.validateFullName('Ahmad123 Ali'), 'Name must contain only letters and spaces');
    });

   test('Very short name', () {
  expect(logic.validateFullName('A B'), null);
});


    test('Valid English name', () {
      expect(logic.validateFullName('Ahmad Ali'), null);
    });

    test('Valid Arabic name', () {
      expect(logic.validateFullName('أحمد علي'), null);
    });
  });

  group('National ID Validation', () {
    test('Empty national ID', () {
      expect(logic.validateNationalID(''), 'Please enter national ID');
    });

    test('National ID with letters', () {
      expect(logic.validateNationalID('12345abcde'), 'National ID must contain only digits');
    });

    test('National ID less than 10 digits', () {
      expect(logic.validateNationalID('123'), 'National ID must be 10 digits');
    });

    test('National ID more than 10 digits', () {
      expect(logic.validateNationalID('123456789012'), 'National ID must be 10 digits');
    });

    test('Valid national ID', () {
      expect(logic.validateNationalID('1234567890'), null);
    });
  });

  group('Birth Date Validation', () {
    test('Empty birth date', () {
      expect(logic.validateBirthDate(''), 'Please enter date of birth');
    });

    test('Invalid format', () {
      expect(logic.validateBirthDate('2000-01-01'), 'Format: DD/MM/YYYY');
    });

    test('Under 18 years old', () {
      expect(logic.validateBirthDate('01/01/2015'), 'Must be 18 years or older');
    });

    test('Valid birth date', () {
      expect(logic.validateBirthDate('01/01/2000'), null);
    });
  });

  group('Phone Number Validation', () {
    test('Empty phone number', () {
      expect(logic.validatePhone(''), 'Please enter phone number');
    });

    test('Less than 10 digits', () {
      expect(logic.validatePhone('077123456'), 'Phone must be 10 digits');
    });

    test('Does not start with 07', () {
      expect(logic.validatePhone('0612345678'), 'Invalid phone number');
    });

    test('Valid phone 077', () {
      expect(logic.validatePhone('0771234567'), null);
    });

    test('Valid phone 078', () {
      expect(logic.validatePhone('0781234567'), null);
    });

    test('Valid phone 079', () {
      expect(logic.validatePhone('0791234567'), null);
    });
  });

  group('Withdrawal Code', () {
    test('Code is generated', () {
      final code = logic.generateWithdrawalCode();
      expect(code.isNotEmpty, true);
    });

    test('Code starts with RTL-', () {
      final code = logic.generateWithdrawalCode();
      expect(code.startsWith('RTL-'), true);
    });
  });
}
