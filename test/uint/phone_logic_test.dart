import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/continue_create_account_logic.dart';

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
      expect(ContinueCreateAccountLogic.validatePhoneNumber('0771234567'), isNull); //
expect(ContinueCreateAccountLogic.validatePhoneNumber('+962771234567'), isNull); //
expect(ContinueCreateAccountLogic.validatePhoneNumber('962781234567'), isNull); //
    });

    test('validateIdImage', () {
      expect(ContinueCreateAccountLogic.validateIdImage(sampleFile), isNull); //
      final nonExist = File('test/resources/nonexist.jpg');
      expect(ContinueCreateAccountLogic.validateIdImage(nonExist), isNotNull); //
      expect(ContinueCreateAccountLogic.validateIdImage(null), isNotNull); //
    });

    test('validateFaceImage', () {
      expect(ContinueCreateAccountLogic.validateFaceImage(sampleFile, true), isNull); // موجود + وجه مكتشف
      expect(ContinueCreateAccountLogic.validateFaceImage(sampleFile, false), isNotNull); // موجود + وجه غير مكتشف
      final nonExist = File('test/resources/nonexist.jpg');
      expect(ContinueCreateAccountLogic.validateFaceImage(nonExist, true), isNotNull); // ملف غير موجود
      expect(ContinueCreateAccountLogic.validateFaceImage(null, true), isNotNull); // null
    });

    test('validateFirstName and validateLastName', () {
      expect(ContinueCreateAccountLogic.validateFirstName(''), isNotNull);
      expect(ContinueCreateAccountLogic.validateFirstName('A'), isNotNull);
      expect(ContinueCreateAccountLogic.validateFirstName('John'), isNull);
      expect(ContinueCreateAccountLogic.validateLastName(''), isNotNull);
      expect(ContinueCreateAccountLogic.validateLastName('X'), isNotNull);
      expect(ContinueCreateAccountLogic.validateLastName('Doe'), isNull);
      
      expect(ContinueCreateAccountLogic.validateFirstName('قصي'), isNull);
      expect(ContinueCreateAccountLogic.validateLastName('القرعان'), isNull);
    });

    test('validateBirthDate', () {
      expect(ContinueCreateAccountLogic.validateBirthDate(''), isNotNull);
      expect(ContinueCreateAccountLogic.validateBirthDate('01-01-2000'), isNotNull); // خطأ في الصيغة
      expect(ContinueCreateAccountLogic.validateBirthDate('2000-01-01'), isNull); // صحيح
      expect(ContinueCreateAccountLogic.validateBirthDate('2100-01-01'), isNotNull); // مستقبل
      expect(ContinueCreateAccountLogic.validateBirthDate('1900-01-01'), isNotNull); // عمر كبير جدًا
    });

    test('validateAllFields collects errors', () {
      final errors = ContinueCreateAccountLogic.validateAllFields(
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
  final errors = ContinueCreateAccountLogic.validateAllFields(
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
