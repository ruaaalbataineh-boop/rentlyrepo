import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/login_logic.dart';


void main() {
  group('AuthLogic Email Validation', () {
    test('should return error if email is null', () {
      expect(AuthLogic.validateEmail(null), 'Email is required');
    });

    test('should return error if email is empty', () {
      expect(AuthLogic.validateEmail(''), 'Email is required');
      expect(AuthLogic.validateEmail('   '), 'Email is required');
    });

    test('should return error if email format is invalid', () {
      expect(AuthLogic.validateEmail('invalidEmail'), 'Enter a valid email');
      expect(AuthLogic.validateEmail('test@com'), 'Enter a valid email');
      expect(AuthLogic.validateEmail('test.com'), 'Enter a valid email');
    });

    test('should return null if email is valid', () {
      expect(AuthLogic.validateEmail('test@example.com'), null);
      expect(AuthLogic.validateEmail('user.name@domain.co'), null);
    });
  });

  group('AuthLogic Password Validation', () {
    test('should return error if password is null', () {
      expect(AuthLogic.validatePassword(null), 'Password is required');
    });

    test('should return error if password is empty', () {
      expect(AuthLogic.validatePassword(''), 'Password is required');
    });

    test('should return error if password is less than 6 characters', () {
      expect(AuthLogic.validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('should return null if password is valid', () {
      expect(AuthLogic.validatePassword('123456'), null);
      expect(AuthLogic.validatePassword('mypassword'), null);
    });
  });
}
