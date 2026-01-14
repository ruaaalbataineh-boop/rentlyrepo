import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/create_account_logic.dart';

void main() {
  group('CreateAccountLogic Tests', () {
    test('Email validation - valid emails', () {
      expect(CreateAccountLogic.validateEmail('test@example.com'), isNull);
      expect(CreateAccountLogic.validateEmail('user.name@domain.co'), isNull);
    });

    test('Email validation - empty email', () {
      expect(CreateAccountLogic.validateEmail(''), 'Please enter your email');
    });

    test('Email validation - invalid emails', () {
      expect(CreateAccountLogic.validateEmail('invalid'), 'Invalid email address');
    });

    test('Password validation - valid passwords', () {
      expect(CreateAccountLogic.validatePassword('123456'), isNull);
    });

    test('Password validation - empty password', () {
      expect(CreateAccountLogic.validatePassword(''), 'Please enter your password');
    });

    test('Password validation - too short', () {
      expect(CreateAccountLogic.validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('Extract username from email', () {
      expect(CreateAccountLogic.extractUsername('test@example.com'), 'test');
    });

    test('Email regex validation', () {
      expect(CreateAccountLogic.isValidEmail('test@example.com'), true);
      expect(CreateAccountLogic.isValidEmail('invalid'), false);
    });
  });

  group('Error Messages', () {
    test('All error messages are strings', () {
      const messages = [
        'Please enter your email',
        'Invalid email address',
        'Please enter your password',
        'Password must be at least 6 characters',
      ];
      
      for (final message in messages) {
        expect(message, isA<String>());
      }
    });
  });

  print('✅ CreateAccountLogic tests completed!');
}
