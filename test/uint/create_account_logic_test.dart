import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/create_account_logic.dart';

void main() {
  group('CreateAccountLogic - Correct Understanding of Regex', () {
    test('Regex actually requires a dot in domain part', () {
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      
      expect(regex.hasMatch('user@domain.com'), true);
      expect(regex.hasMatch('a@b.c'), true);
      expect(regex.hasMatch('user@domain.c'), true);
      expect(regex.hasMatch('user@-domain.com'), true);
      expect(regex.hasMatch('user@domain_com'), false); 
      expect(regex.hasMatch('test@localhost'), false); 
    });

    test('validateEmail matches regex behavior exactly', () {
      
      final validEmails = [
        'test@example.com',
        'a@b.c',
        'user@domain.c',
        'user@-domain.com',
        'user.name@domain.co',
      ];

      
      final invalidEmails = [
        'user@domain_com',  
        'test@localhost',   
        'plainaddress',     
        '@domain.com',      
        'user@',            
        'user@domain',      
      ];

      print('=== VALID Emails (should return null) ===');
      for (final email in validEmails) {
        final result = CreateAccountLogic.validateEmail(email);
        print('"$email" -> $result');
        expect(result, isNull, reason: '"$email" should be valid');
      }

      print('\n=== INVALID Emails (should return error) ===');
      for (final email in invalidEmails) {
        final result = CreateAccountLogic.validateEmail(email);
        print('"$email" -> $result');
        
        if (email.isEmpty) {
          expect(result, 'Please enter your email');
        } else {
          expect(result, 'Invalid email address');
        }
      }
    });

    test('validateEmail handles edge cases correctly', () {
      expect(CreateAccountLogic.validateEmail(null), 'Please enter your email');
      expect(CreateAccountLogic.validateEmail(''), 'Please enter your email');
      expect(CreateAccountLogic.validateEmail('   '), 'Please enter your email');
      expect(CreateAccountLogic.validateEmail('  test@example.com  '), isNull);
    });
  });

  group('CreateAccountLogic - Password Validation (unchanged)', () {
    test('validatePassword basic cases', () {
      expect(CreateAccountLogic.validatePassword(null), 'Please enter your password');
      expect(CreateAccountLogic.validatePassword(''), 'Please enter your password');
      expect(CreateAccountLogic.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(CreateAccountLogic.validatePassword('123456'), isNull);
      expect(CreateAccountLogic.validatePassword('password123'), isNull);
    });
  });
}
