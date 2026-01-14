import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/phone_logic.dart';

void main() {
  late File sampleFile;

  setUp(() {
   
    sampleFile = File('test/resources/sample.jpg');
    if (!sampleFile.existsSync()) {
      sampleFile.createSync(recursive: true);
      sampleFile.writeAsBytesSync([0, 1, 2, 3]);
    }
  });

  group('PhoneLogic Tests', () {
    test('validatePhoneNumber', () {
      expect(PhoneLogic.validatePhoneNumber('0771234567'), isNull); // 
expect(PhoneLogic.validatePhoneNumber('+962771234567'), isNull); // 
expect(PhoneLogic.validatePhoneNumber('962781234567'), isNull); // 
    });

    test('validateIdImage', () {
      expect(PhoneLogic.validateIdImage(sampleFile), isNull); // 
      final nonExist = File('test/resources/nonexist.jpg');
      expect(PhoneLogic.validateIdImage(nonExist), isNotNull); //  
      expect(PhoneLogic.validateIdImage(null), isNotNull); // 
    });

    test('validateFaceImage', () {
      expect(PhoneLogic.validateFaceImage(sampleFile, true), isNull); // موجود + وجه مكتشف
      expect(PhoneLogic.validateFaceImage(sampleFile, false), isNotNull); // موجود + وجه غير مكتشف
      final nonExist = File('test/resources/nonexist.jpg');
      expect(PhoneLogic.validateFaceImage(nonExist, true), isNotNull); // ملف غير موجود
      expect(PhoneLogic.validateFaceImage(null, true), isNotNull); // null
    });

    test('validateFirstName and validateLastName', () {
      expect(PhoneLogic.validateFirstName(''), isNotNull);
      expect(PhoneLogic.validateFirstName('A'), isNotNull);
      expect(PhoneLogic.validateFirstName('John'), isNull);
      expect(PhoneLogic.validateLastName(''), isNotNull);
      expect(PhoneLogic.validateLastName('X'), isNotNull);
      expect(PhoneLogic.validateLastName('Doe'), isNull);
      
      expect(PhoneLogic.validateFirstName('قصي'), isNull);
      expect(PhoneLogic.validateLastName('القرعان'), isNull);
    });

    test('validateBirthDate', () {
      expect(PhoneLogic.validateBirthDate(''), isNotNull);
      expect(PhoneLogic.validateBirthDate('01-01-2000'), isNotNull); // خطأ في الصيغة
      expect(PhoneLogic.validateBirthDate('2000-01-01'), isNull); // صحيح
      expect(PhoneLogic.validateBirthDate('2100-01-01'), isNotNull); // مستقبل
      expect(PhoneLogic.validateBirthDate('1900-01-01'), isNotNull); // عمر كبير جدًا
    });

    test('validateAllFields collects errors', () {
      final errors = PhoneLogic.validateAllFields(
        firstName: '', 
        lastName: 'X', 
        birthDate: '2020-01-01', 
        phone: '123', 
        idImage: null, 
        faceImage: null, 
        faceDetected: false,
      );
      expect(errors.length, greaterThan(0));
    });

   test('validateAllFields passes with valid data', () {
  final errors = PhoneLogic.validateAllFields(
    firstName: 'John',
    lastName: 'Doe',
    birthDate: '2000-01-01',
    phone: '0771234567',  
    idImage: sampleFile,  
    faceImage: sampleFile,
    faceDetected: true,
  );
  expect(errors.isEmpty, true);
});

  });
}
