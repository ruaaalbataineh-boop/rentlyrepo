
import 'dart:async';

class CodeLogic {
  List<String> code;
  String serverCode;
  
  CodeLogic({
    List<String>? code,
    String? serverCode,
  }) : code = code ?? ["", "", "", ""],
       serverCode = serverCode ?? "1234";

  
  bool addDigit(String digit) {
    
    if (!_isValidDigit(digit)) {
      return false;
    }
    
    for (int i = 0; i < code.length; i++) {
      if (code[i].isEmpty) {
        code[i] = digit;
        return true;
      }
    }
    return false; 
  }

  void removeDigit() {
    for (int i = code.length - 1; i >= 0; i--) {
      if (code[i].isNotEmpty) {
        code[i] = "";
        break;
      }
    }
  }

  Future<bool> verifyCode(String inputCode) async {
    await Future.delayed(const Duration(seconds: 1));
    return inputCode == serverCode;
  }

  void resendCode() {
    serverCode = "4321";
  }

  
  String? validateCode() {
    final enteredCode = getEnteredCode();
    
    if (enteredCode.isEmpty) {
      return "Please enter the code";
    }
    
    if (enteredCode.length < 4) {
      return "Please enter all 4 digits";
    }
    
    return null;
  }

  bool isCodeComplete() {
    return code.every((digit) => digit.isNotEmpty);
  }

  
  String getEnteredCode() {
    return code.join();
  }

  void clearCode() {
    code = ["", "", "", ""];
  }

  int getFilledCount() {
    return code.where((digit) => digit.isNotEmpty).length;
  }

  bool isEmpty() {
    return code.every((digit) => digit.isEmpty);
  }

  bool _isValidDigit(String digit) {
    if (digit.isEmpty) return false;
   
    if (digit.length != 1) return false;
    
   
    final codeUnit = digit.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57; 
  }
}
