
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/personal_info_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PersonalInfoProvider Tests', () {
    late PersonalInfoProvider provider;

    setUp(() {
      provider = PersonalInfoProvider();
    
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial values should be empty', () {
      expect(provider.name, '');
      expect(provider.email, '');
      expect(provider.password, '');
      expect(provider.phone, '');
      expect(provider.imageFile, isNull);
    });

    test('toMap should return correct data structure', () {
      provider.name = 'John Doe';
      provider.email = 'john@example.com';
      
      final map = provider.toMap();
      
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['password'], '');
      expect(map['phone'], '');
      expect(map['hasImage'], false);
    });

    test('Save and load user data', () async {
      
      SharedPreferences.setMockInitialValues({
        'name': 'Alice',
        'email': 'alice@example.com',
        'password': 'password123',
        'phone': '1234567890',
      });

      await provider.loadUserData();
      
      expect(provider.name, 'Alice');
      expect(provider.email, 'alice@example.com');
      expect(provider.password, 'password123');
      expect(provider.phone, '1234567890');
    });

    test('Save user data', () async {
      provider.name = 'Bob';
      provider.email = 'bob@example.com';
      provider.password = 'securepass';
      provider.phone = '9876543210';
      
      await provider.saveUserData();
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('name'), 'Bob');
      expect(prefs.getString('email'), 'bob@example.com');
      expect(prefs.getString('password'), 'securepass');
      expect(prefs.getString('phone'), '9876543210');
    });

    test('Empty data handling', () async {
      await provider.saveUserData();
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('name'), '');
      expect(prefs.getString('email'), '');
      expect(prefs.getString('password'), '');
      expect(prefs.getString('phone'), '');
    });

    test('Data overwriting', () async {
    
      provider.name = 'First';
      provider.email = 'first@example.com';
      await provider.saveUserData();
      
    
      provider.name = 'Second';
      provider.email = 'second@example.com';
      await provider.saveUserData();
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('name'), 'Second');
      expect(prefs.getString('email'), 'second@example.com');
    });
  });
}
