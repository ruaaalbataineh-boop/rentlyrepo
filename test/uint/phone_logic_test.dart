import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/phone_logic.dart';
import 'dart:io';

void main() {
  group('PhoneLogic Unit Tests', () {
    test('First Name validation works correctly', () {
      expect(PhoneLogic.validateFirstName('Ahmed'), isNull);
      expect(PhoneLogic.validateFirstName('Mohammad'), isNull);
      expect(PhoneLogic.validateFirstName('Qusay'), isNull);
      
      expect(PhoneLogic.validateFirstName(''), 'Please enter your first name');
      expect(PhoneLogic.validateFirstName(' '), 'Please enter your first name');
      expect(PhoneLogic.validateFirstName('A'), 'First name must be at least 2 characters');
      expect(PhoneLogic.validateFirstName('123'), 'First name can only contain letters, spaces, and hyphens');
      expect(PhoneLogic.validateFirstName('Ahmed123'), 'First name can only contain letters, spaces, and hyphens');
    });

    test('Last Name validation works correctly', () {
      expect(PhoneLogic.validateLastName('AAA'), isNull);
      expect(PhoneLogic.validateLastName('BBB'), isNull);
      expect(PhoneLogic.validateLastName('CCC'), isNull);
      
      expect(PhoneLogic.validateLastName(''), 'Please enter your last name');
      expect(PhoneLogic.validateLastName(' '), 'Please enter your last name');
      expect(PhoneLogic.validateLastName('A'), 'Last name must be at least 2 characters');
      expect(PhoneLogic.validateLastName('AAA123'), 'Last name can only contain letters, spaces, and hyphens');
    });

    test('Birth Date validation works correctly', () {
      expect(PhoneLogic.validateBirthDate('1990-01-15'), isNull);
      expect(PhoneLogic.validateBirthDate('2000-12-31'), isNull);
      
      expect(PhoneLogic.validateBirthDate(''), 'Please select your birth date');
      expect(PhoneLogic.validateBirthDate(' '), 'Please select your birth date');
      expect(PhoneLogic.validateBirthDate('1990/01/15'), 'Invalid date format. Use YYYY-MM-DD');
      expect(PhoneLogic.validateBirthDate('15-01-1990'), 'Invalid date format. Use YYYY-MM-DD');
      expect(PhoneLogic.validateBirthDate('2025-01-01'), 'Birth date cannot be in the future');
      expect(PhoneLogic.validateBirthDate('2020-01-01'), 'You must be at least 18 years old');
      expect(PhoneLogic.validateBirthDate('1800-01-01'), 'Please enter a valid birth date');
      expect(PhoneLogic.validateBirthDate('1990-13-01'), 'Invalid date');
      expect(PhoneLogic.validateBirthDate('1990-02-30'), 'Invalid date');
    });

    test('Phone Number validation works correctly', () {
      expect(PhoneLogic.validatePhoneNumber('791234567'), isNull);  
      expect(PhoneLogic.validatePhoneNumber('781234567'), isNull);  
      expect(PhoneLogic.validatePhoneNumber('771234567'), isNull);  
      expect(PhoneLogic.validatePhoneNumber('+962791234567'), isNull);  
      expect(PhoneLogic.validatePhoneNumber('0791234567'), isNull);     
      
      expect(PhoneLogic.validatePhoneNumber(''), 'Please enter your phone number');
      expect(PhoneLogic.validatePhoneNumber(' '), 'Please enter your phone number');
      expect(PhoneLogic.validatePhoneNumber('123'), 'Phone number must be 9 digits (after country code)');
      expect(PhoneLogic.validatePhoneNumber('1234567890'), 'Phone number must be 9 digits (after country code)');
      expect(PhoneLogic.validatePhoneNumber('691234567'), 'Jordanian mobile numbers must start with 7');
      expect(PhoneLogic.validatePhoneNumber('761234567'), 'Second digit must be 7, 8, or 9');
    });

    test('Get full name correctly', () {
      String normalize(String str) {
        return str.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
     
      expect(
        normalize(PhoneLogic.getFullName('Qusay', 'AAA')),
        normalize('Qusay AAA')
      );
      
      expect(
        normalize(PhoneLogic.getFullName('Ahmed', 'BBB')),
        normalize('Ahmed BBB')
      );
      
      expect(
        normalize(PhoneLogic.getFullName('  Mohammad  ', '  CCC  ')),
        normalize('Mohammad CCC')
      );
      
      expect(PhoneLogic.getFullName('Qusay', ''), 'Qusay');
      expect(PhoneLogic.getFullName('', 'AAA'), 'AAA');
      expect(PhoneLogic.getFullName('', ''), '');
      expect(PhoneLogic.getFullName('   ', '   '), '');
      
      expect(
        normalize(PhoneLogic.getFullName('Abdul   Rahman', 'DDD')),
        normalize('Abdul Rahman DDD')
      );
      
      final result = PhoneLogic.getFullName('Ahmed', 'BBB');
      expect(result, isNotNull);
      expect(result.isNotEmpty, isTrue);
      expect(result.contains('Ahmed'), isTrue);
      expect(result.contains('BBB'), isTrue);
    });

    test('Format date correctly', () {
      expect(PhoneLogic.formatDate(DateTime(1990, 1, 15)), '1990-01-15');
      expect(PhoneLogic.formatDate(DateTime(2000, 12, 31)), '2000-12-31');
      expect(PhoneLogic.formatDate(DateTime(1990, 10, 5)), '1990-10-05');
      expect(PhoneLogic.formatDate(DateTime(1990, 9, 15)), '1990-09-15');
    });

    test('Check if person is adult', () {
      expect(PhoneLogic.isAdult('2000-01-01'), isTrue);
      expect(PhoneLogic.isAdult('2010-01-01'), isFalse);
      expect(PhoneLogic.isAdult('invalid'), isFalse);
      expect(PhoneLogic.isAdult(''), isFalse);
      
      expect(PhoneLogic.calculateAge('2000-01-01'), greaterThan(18));
      expect(PhoneLogic.calculateAge('2010-01-01'), lessThan(18));
    });

    test('Complete validation returns all errors', () {
      final errors = PhoneLogic.validateAllFields(
        firstName: '',
        lastName: '',
        birthDate: '',
        phone: '',
        idImage: null,
        faceImage: null,
        faceDetected: false,
      );
      
      expect(errors.length, 6);
      expect(errors.contains('Please enter your first name'), isTrue);
      expect(errors.contains('Please enter your last name'), isTrue);
      expect(errors.contains('Please select your birth date'), isTrue);
      expect(errors.contains('Please enter your phone number'), isTrue);
      expect(errors.contains('Please upload your ID photo'), isTrue);
      expect(errors.contains('Please upload your face photo'), isTrue);
    });

    test('Complete validation with partial valid data', () {
      final mockIdImage = File('test_id.jpg');
      final mockFaceImage = File('test_face.jpg');
      
      final errors = PhoneLogic.validateAllFields(
        firstName: 'Qusay',
        lastName: 'AAA',
        birthDate: '1990-01-15',
        phone: '791234567',
        idImage: mockIdImage,
        faceImage: mockFaceImage,
        faceDetected: true,
      );
      
      expect(errors.length, greaterThan(0));
      expect(errors.any((e) => e.contains('not found')), isTrue);
    });

    test('Format phone number correctly', () {
      expect(PhoneLogic.formatPhoneNumber('791234567'), '+962 791234567');
      expect(PhoneLogic.formatPhoneNumber('0791234567'), '+962 791234567');
      expect(PhoneLogic.formatPhoneNumber('962791234567'), '+962791234567');
      expect(PhoneLogic.formatPhoneNumber('+962791234567'), '+962791234567');
      expect(PhoneLogic.formatPhoneNumber('invalid'), 'invalid');
    });

    test('Static methods work without instance', () {
      expect(() => PhoneLogic.validateFirstName('Qusay'), returnsNormally);
      expect(() => PhoneLogic.validateLastName('AAA'), returnsNormally);
      expect(() => PhoneLogic.validateBirthDate('1990-01-01'), returnsNormally);
      expect(() => PhoneLogic.validatePhoneNumber('791234567'), returnsNormally);
      expect(() => PhoneLogic.getFullName('Qusay', 'AAA'), returnsNormally);
      expect(() => PhoneLogic.formatDate(DateTime.now()), returnsNormally);
      expect(() => PhoneLogic.isAdult('1990-01-01'), returnsNormally);
    });
  });
}
