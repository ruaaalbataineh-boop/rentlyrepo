import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p2/logic/personal_info_logic.dart';

void main() {
  late PersonalInfoProvider provider;

  setUp(() {
    
    SharedPreferences.setMockInitialValues({});
    provider = PersonalInfoProvider();
  });

  test('toMap should return correct structure', () {
    
    provider.name = 'John Doe';
    provider.email = 'john@test.com';
    provider.password = 'password123';
    provider.phone = '0791234567';

    
    final result = provider.toMap();

    
    expect(result['name'], 'John Doe');
    expect(result['email'], 'john@test.com');
    expect(result['hasPassword'], true);
    expect(result['phone'], '0791234567');
    expect(result['hasImage'], false);
  });

  test('sanitizeAndEncrypt should handle regular text', () {
    final result = provider.sanitizeAndEncrypt('  test text  ', 'name');
    expect(result, 'test text');
  });

  test('sanitizeAndEncrypt should handle password', () {
    final result = provider.sanitizeAndEncrypt('mypassword', 'password');
    expect(result, startsWith('encrypted_'));
  });

  test('sanitizeAndDecrypt should mask password', () {
    final result = provider.sanitizeAndDecrypt('encrypted_123', 'password');
    expect(result, '******');
  });

  test('sanitizeAndDecrypt should return text as-is for non-password', () {
    final result = provider.sanitizeAndDecrypt('test', 'name');
    expect(result, 'test');
  });

  test('validateCurrentData should return true for valid data', () {
    provider.name = 'John';
    provider.email = 'john@test.com';
    provider.phone = '+962791234567';
    
    expect(provider.validateCurrentData(), true);
  });

  test('validateCurrentData should return false for empty name', () {
    provider.name = '';
    provider.email = 'test@test.com';
    
    expect(provider.validateCurrentData(), false);
  });

  test('validateCurrentData should return false for invalid email', () {
    provider.name = 'John';
    provider.email = 'invalid-email';
    
    expect(provider.validateCurrentData(), false);
  });

  test('validateCurrentData should accept empty phone', () {
    provider.name = 'John';
    provider.email = 'test@test.com';
    provider.phone = '';
    
    expect(provider.validateCurrentData(), true);
  });

  test('Setting and getting property values', () {

    provider.name = 'Test User';
    expect(provider.name, 'Test User');

   
    provider.email = 'test@example.com';
    expect(provider.email, 'test@example.com');

  
    provider.phone = '0791234567';
    expect(provider.phone, '0791234567');

    provider.password = 'Test123!';
    expect(provider.password, 'Test123!');
  });

  test('clearSensitiveData should clear password', () async {
    
    provider.password = 'secret123';

    
    await provider.clearSensitiveData();

    
    expect(provider.password, '');
  });

  
  test('clearSensitiveData should work multiple times', () async {
    provider.password = 'first';
    await provider.clearSensitiveData();
    expect(provider.password, '');

    provider.password = 'second';
    await provider.clearSensitiveData();
    expect(provider.password, '');
  });
}
