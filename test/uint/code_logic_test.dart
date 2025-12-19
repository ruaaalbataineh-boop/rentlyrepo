import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/code_logic.dart';

void main() {
  group('CodeLogic Unit Tests', () {
    late CodeLogic codeLogic;

    setUp(() {
      codeLogic = CodeLogic();
    });

    test('Initial state is correct', () {
      expect(codeLogic.code, ['', '', '', '']);
      expect(codeLogic.serverCode, '1234');
      expect(codeLogic.isEmpty(), true);
      expect(codeLogic.isCodeComplete(), false);
      expect(codeLogic.getFilledCount(), 0);
      expect(codeLogic.getEnteredCode(), '');
    });

    test('Add digit fills boxes in order', () {
      expect(codeLogic.addDigit('1'), true);
      expect(codeLogic.code, ['1', '', '', '']);
      expect(codeLogic.getFilledCount(), 1);
      
      expect(codeLogic.addDigit('2'), true);
      expect(codeLogic.code, ['1', '2', '', '']);
      expect(codeLogic.getFilledCount(), 2);
      
      expect(codeLogic.addDigit('3'), true);
      expect(codeLogic.code, ['1', '2', '3', '']);
      expect(codeLogic.getFilledCount(), 3);
      
      expect(codeLogic.addDigit('4'), true);
      expect(codeLogic.code, ['1', '2', '3', '4']);
      expect(codeLogic.getFilledCount(), 4);
    });

    test('Add digit returns false when all boxes full', () {
      expect(codeLogic.addDigit('1'), true);
      expect(codeLogic.addDigit('2'), true);
      expect(codeLogic.addDigit('3'), true);
      expect(codeLogic.addDigit('4'), true);
      
      expect(codeLogic.addDigit('5'), false);
      expect(codeLogic.code, ['1', '2', '3', '4']);
    });

    test('Valid digits 0-9 are accepted', () {
      for (int i = 0; i <= 9; i++) {
        codeLogic.clearCode();
        expect(codeLogic.addDigit(i.toString()), true);
        expect(codeLogic.code[0], i.toString());
      }
    });

    test('Invalid characters are rejected', () {
      expect(codeLogic.addDigit('A'), false);
      expect(codeLogic.addDigit(''), false);
      expect(codeLogic.addDigit('12'), false);
      expect(codeLogic.addDigit('@'), false);
      expect(codeLogic.addDigit(' '), false);
      expect(codeLogic.addDigit('/'), false);
      expect(codeLogic.addDigit(':'), false);
      
      expect(codeLogic.code, ['', '', '', '']);
    });

    
    test('Remove digit clears boxes in reverse order', () {
      codeLogic.addDigit('1');
      codeLogic.addDigit('2');
      codeLogic.addDigit('3');
      codeLogic.addDigit('4');
      
      codeLogic.removeDigit();
      expect(codeLogic.code, ['1', '2', '3', '']);
      
      codeLogic.removeDigit();
      expect(codeLogic.code, ['1', '2', '', '']);
      
      codeLogic.removeDigit();
      expect(codeLogic.code, ['1', '', '', '']);
      
      codeLogic.removeDigit();
      expect(codeLogic.code, ['', '', '', '']);
    });

    test('Remove digit from empty does nothing', () {
      expect(codeLogic.isEmpty(), true);
      
      codeLogic.removeDigit();
      expect(codeLogic.code, ['', '', '', '']);
      
      codeLogic.addDigit('1');
      codeLogic.removeDigit();
      codeLogic.removeDigit();
      expect(codeLogic.code, ['', '', '', '']);
    });

    test('Get entered code returns correct string', () {
      expect(codeLogic.getEnteredCode(), '');
      
      codeLogic.addDigit('1');
      expect(codeLogic.getEnteredCode(), '1');
      
      codeLogic.addDigit('2');
      expect(codeLogic.getEnteredCode(), '12');
      
      codeLogic.addDigit('3');
      expect(codeLogic.getEnteredCode(), '123');
      
      codeLogic.addDigit('4');
      expect(codeLogic.getEnteredCode(), '1234');
    });

    test('Clear code resets to empty', () {
      codeLogic.addDigit('1');
      codeLogic.addDigit('2');
      codeLogic.addDigit('3');
      
      codeLogic.clearCode();
      
      expect(codeLogic.code, ['', '', '', '']);
      expect(codeLogic.getFilledCount(), 0);
      expect(codeLogic.getEnteredCode(), '');
    });

  
    test('Verify code returns correct result', () async {
      expect(await codeLogic.verifyCode('1234'), true);
      expect(await codeLogic.verifyCode('1111'), false);
      expect(await codeLogic.verifyCode(''), false);
    });

    test('Verification has delay', () async {
      final stopwatch = Stopwatch()..start();
      await codeLogic.verifyCode('1234');
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(900));
    });

    test('Resend code changes server code', () {
      expect(codeLogic.serverCode, '1234');
      
      codeLogic.resendCode();
      expect(codeLogic.serverCode, '4321');
    });

    
    test('Validate code returns correct errors', () {
      expect(codeLogic.validateCode(), 'Please enter the code');
      
      codeLogic.addDigit('1');
      expect(codeLogic.validateCode(), 'Please enter all 4 digits');
      
      codeLogic.addDigit('2');
      expect(codeLogic.validateCode(), 'Please enter all 4 digits');
      
      codeLogic.addDigit('3');
      expect(codeLogic.validateCode(), 'Please enter all 4 digits');
      
      codeLogic.addDigit('4');
      expect(codeLogic.validateCode(), isNull);
    });

    test('Is code complete works correctly', () {
      expect(codeLogic.isCodeComplete(), false);
      
      codeLogic.addDigit('1');
      expect(codeLogic.isCodeComplete(), false);
      
      codeLogic.addDigit('2');
      codeLogic.addDigit('3');
      codeLogic.addDigit('4');
      expect(codeLogic.isCodeComplete(), true);
      
      codeLogic.removeDigit();
      expect(codeLogic.isCodeComplete(), false);
    });

    test('Get filled count works correctly', () {
      expect(codeLogic.getFilledCount(), 0);
      
      codeLogic.addDigit('1');
      expect(codeLogic.getFilledCount(), 1);
      
      codeLogic.addDigit('2');
      expect(codeLogic.getFilledCount(), 2);
      
      codeLogic.addDigit('3');
      expect(codeLogic.getFilledCount(), 3);
      
      codeLogic.addDigit('4');
      expect(codeLogic.getFilledCount(), 4);
      
      codeLogic.removeDigit();
      expect(codeLogic.getFilledCount(), 3);
    });

    test('Is empty works correctly', () {
      expect(codeLogic.isEmpty(), true);
      
      codeLogic.addDigit('1');
      expect(codeLogic.isEmpty(), false);
      
      codeLogic.removeDigit();
      expect(codeLogic.isEmpty(), true);
    });

    
    test('Constructor with custom values', () {
      final customLogic = CodeLogic(
        code: ['5', '6', '7', '8'],
        serverCode: '9999',
      );
      
      expect(customLogic.code, ['5', '6', '7', '8']);
      expect(customLogic.serverCode, '9999');
      expect(customLogic.getEnteredCode(), '5678');
    });

    test('Constructor with partial code', () {
      final customLogic = CodeLogic(
        code: ['1', '2', '', ''],
        serverCode: '1111',
      );
      
      expect(customLogic.code, ['1', '2', '', '']);
      expect(customLogic.getEnteredCode(), '12');
      expect(customLogic.isCodeComplete(), false);
      expect(customLogic.getFilledCount(), 2);
    });

    
    test('Edge case: add and remove mixed operations', () {
      expect(codeLogic.addDigit('1'), true);
      expect(codeLogic.addDigit('A'), false);
      expect(codeLogic.addDigit('2'), true);
      expect(codeLogic.getEnteredCode(), '12');
      
      codeLogic.removeDigit();
      expect(codeLogic.getEnteredCode(), '1');
      
      expect(codeLogic.addDigit('@'), false);
      expect(codeLogic.addDigit('3'), true);
      expect(codeLogic.getEnteredCode(), '13');
    });

    test('Edge case: fill, clear, refill', () {
      codeLogic.addDigit('1');
      codeLogic.addDigit('2');
      codeLogic.addDigit('3');
      codeLogic.addDigit('4');
      
      expect(codeLogic.isCodeComplete(), true);
      
      codeLogic.clearCode();
      expect(codeLogic.isEmpty(), true);
      
      codeLogic.addDigit('9');
      codeLogic.addDigit('8');
      codeLogic.addDigit('7');
      codeLogic.addDigit('6');
      
      expect(codeLogic.getEnteredCode(), '9876');
      expect(codeLogic.isCodeComplete(), true);
    });

    test('Edge case: multiple removes on partial code', () {
      codeLogic.addDigit('1');
      codeLogic.addDigit('2');
      
      codeLogic.removeDigit();
      codeLogic.removeDigit();
      codeLogic.removeDigit();
      codeLogic.removeDigit();
      codeLogic.removeDigit();
      
      expect(codeLogic.isEmpty(), true);
      expect(codeLogic.getFilledCount(), 0);
    });

    test('Edge case: validate after clear', () {
      codeLogic.addDigit('1');
      codeLogic.addDigit('2');
      expect(codeLogic.validateCode(), 'Please enter all 4 digits');
      
      codeLogic.clearCode();
      expect(codeLogic.validateCode(), 'Please enter the code');
    });
  });
}
