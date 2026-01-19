import 'package:flutter_test/flutter_test.dart';
import 'package:p2/services/auth_service.dart';

void main() {
  group('AuthService Unit Tests - Validation Logic', () {

    

    test('validateEmail returns error when email is null', () {
      final result = AuthService.validateEmail(null);
      expect(result, 'Email is required');
    });

    test('validateEmail returns error when email is empty', () {
      final result = AuthService.validateEmail('');
      expect(result, 'Email is required');
    });

    test('validateEmail returns error for invalid email format', () {
      final result = AuthService.validateEmail('testemail.com');
      expect(result, 'Enter a valid email');
    });

    test('validateEmail returns null for valid email', () {
      final result = AuthService.validateEmail('test@example.com');
      expect(result, null);
    });

    

    test('validatePassword returns error when password is null', () {
      final result = AuthService.validatePassword(null);
      expect(result, 'Password is required');
    });

    test('validatePassword returns error when password is empty', () {
      final result = AuthService.validatePassword('');
      expect(result, 'Password is required');
    });

    test('validatePassword returns error for short password', () {
      final result = AuthService.validatePassword('123');
      expect(result, 'Password must be at least 6 characters');
    });

    test('validatePassword returns null for valid password', () {
      final result = AuthService.validatePassword('123456');
      expect(result, null);
    });
  });
}
