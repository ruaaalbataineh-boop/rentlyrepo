import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/profile_logic_page.dart';

void main() {
  group('ProfileLogic', () {
    late ProfileLogic logic;

    setUp(() {
      logic = ProfileLogic(
        fullName: 'Qusay',
        email: 'qusay@example.com',
        phone: '1234567890',
        location: 'Irbid',
        bank: 'Jordanian Bank',
      );
    });

    test('Initial values are set correctly', () {
      expect(logic.fullName, 'Qusay');
      expect(logic.email, 'qusay@example.com');
      expect(logic.phone, '1234567890');
      expect(logic.location, 'Irbid');
      expect(logic.bank, 'Jordanian Bank');
      expect(logic.profileImage, isNull);
    });

    test('hasImage returns false when no image', () {
      expect(logic.hasImage(), false);
    });

    test('hasImage returns true when image exists', () {
      logic.profileImage = File('test_path');
      expect(logic.hasImage(), true);
    });

    test('validateForm returns true for valid data', () {
      expect(logic.validateForm('Qusay', 'qusay@test.com', '123456'), true);
    });

    test('validateForm returns false for empty data', () {
      expect(logic.validateForm('', 'qusay@test.com', '123456'), false);
      expect(logic.validateForm('Qusay', '', '123456'), false);
      expect(logic.validateForm('Qusay', 'qusay@test.com', ''), false);
      expect(logic.validateForm('', '', ''), false);
    });

    test('validateForm returns false for null data', () {
      expect(logic.validateForm(null, 'qusay@test.com', '123456'), false);
      expect(logic.validateForm('Qusay', null, '123456'), false);
      expect(logic.validateForm('Qusay', 'qusay@test.com', null), false);
      expect(logic.validateForm(null, null, null), false);
    });

    test('updateProfile updates values correctly', () {
      logic.updateProfile(
        name: 'Ahmed',
        email: 'ahmed@example.com',
        phone: '9876543210',
      );

      expect(logic.fullName, 'Ahmed');
      expect(logic.email, 'ahmed@example.com');
      expect(logic.phone, '9876543210');
    });

    test('updateProfile updates image', () {
      final testFile = File('test_path');
      logic.updateProfile(image: testFile);
      expect(logic.profileImage, testFile);
    });

    test('getProfileData returns correct map', () {
      final data = logic.getProfileData();
      
      expect(data['fullName'], 'Qusay');
      expect(data['email'], 'qusay@example.com');
      expect(data['phone'], '1234567890');
      expect(data['location'], 'Irbid');
      expect(data['bank'], 'Jordanian Bank');
      expect(data['hasImage'], false);
    });

    test('getUpdateSuccessMessage returns correct message', () {
      expect(logic.getUpdateSuccessMessage(), "Profile Updated Successfully!");
    });

    test('getUpdateErrorMessage returns correct message', () {
      expect(logic.getUpdateErrorMessage(), "Failed to update profile");
    });

    test('isProfileChanged returns false for same data', () {
      expect(logic.isProfileChanged(
        name: 'Qusay',
        email: 'qusay@example.com',
        phone: '1234567890',
      ), false);
    });

    test('isProfileChanged returns true for different name', () {
      expect(logic.isProfileChanged(
        name: 'Ahmed',
        email: 'qusay@example.com',
        phone: '1234567890',
      ), true);
    });

    test('isProfileChanged returns true for different email', () {
      expect(logic.isProfileChanged(
        name: 'Qusay',
        email: 'ahmed@example.com',
        phone: '1234567890',
      ), true);
    });

    test('isProfileChanged returns true for different phone', () {
      expect(logic.isProfileChanged(
        name: 'Qusay',
        email: 'qusay@example.com',
        phone: '9876543210',
      ), true);
    });

    test('isProfileChanged returns true for new image', () {
      final testFile = File('test_path');
      expect(logic.isProfileChanged(image: testFile), true);
    });

    test('Partial update with null values', () {
      logic.updateProfile(name: 'Ahmed');
      expect(logic.fullName, 'Ahmed');
      expect(logic.email, 'qusay@example.com'); 
    });
  });
}
