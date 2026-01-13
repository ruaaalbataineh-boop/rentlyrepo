// lib/logic/code_logic.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:convert';
// Add security imports
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';


class CodeLogic {
  List<String> code;
  String serverCode;
  
  // Security variables
  int _attempts = 0;
  final int _maxAttempts = 5;
  DateTime? _lastAttemptTime;
  final Duration _lockoutDuration = const Duration(minutes: 5);
  bool _isLocked = false;
  Timer? _lockoutTimer;
  String? _userId;
  
  CodeLogic({
    List<String>? code,
    String? serverCode,
    String? userId,
  }) : code = code ?? ["", "", "", ""],
       serverCode = serverCode ?? _generateSecureCode(),
       _userId = userId {
    _initializeSecurity();
  }

  static String _generateSecureCode() {
    // Security: Generate random 4-digit code
    final random = Random.secure();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<void> _initializeSecurity() async {
    try {
      // Security: Load attempt history
      await _loadAttemptHistory();
      
      // Security: Check if locked out
      _checkLockoutStatus();
      
    } catch (error) {
      ErrorHandler.logError('CodeLogic Initialization', error);
    }
  }

  Future<void> _loadAttemptHistory() async {
    try {
      final attemptsData = await SecureStorage.getData('code_attempts_$_userId');
      if (attemptsData != null) {
        _attempts = int.tryParse(attemptsData) ?? 0;
      }
      
      final lockoutData = await SecureStorage.getData('code_lockout_$_userId');
      if (lockoutData != null) {
        final lockoutTime = DateTime.tryParse(lockoutData);
        if (lockoutTime != null) {
          _lastAttemptTime = lockoutTime;
          _checkLockoutStatus();
        }
      }
    } catch (error) {
      ErrorHandler.logError('Load Attempt History', error);
    }
  }

  Future<void> _saveAttemptHistory() async {
    try {
      await SecureStorage.saveData('code_attempts_$_userId', _attempts.toString());
      if (_lastAttemptTime != null) {
        await SecureStorage.saveData('code_lockout_$_userId', _lastAttemptTime!.toIso8601String());
      }
    } catch (error) {
      ErrorHandler.logError('Save Attempt History', error);
    }
  }

  void _checkLockoutStatus() {
    if (_lastAttemptTime != null) {
      final timeSinceLast = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLast < _lockoutDuration) {
        _isLocked = true;
        _startLockoutTimer();
      } else {
        _isLocked = false;
      }
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    
    if (_lastAttemptTime != null) {
      final remaining = _lockoutDuration - DateTime.now().difference(_lastAttemptTime!);
      if (remaining > Duration.zero) {
        _lockoutTimer = Timer(remaining, () {
          _isLocked = false;
          _attempts = 0;
          _saveAttemptHistory();
        });
      }
    }
  }

  // Security: Add digit with validation and rate limiting
  bool addDigit(String digit) {
    try {
      // Security: Check if locked
      if (_isLocked) {
        _logSecurityEvent('Attempt to add digit while locked out');
        return false;
      }

      // Security: Validate digit
      if (!_isValidDigit(digit)) {
        _logSecurityEvent('Invalid digit attempt: $digit');
        return false;
      }
      
      // Security: Sanitize input
      final sanitizedDigit = InputValidator.sanitizeInput(digit);
      if (sanitizedDigit.isEmpty || sanitizedDigit.length != 1) {
        return false;
      }
      
      // Find empty slot
      for (int i = 0; i < code.length; i++) {
        if (code[i].isEmpty) {
          code[i] = sanitizedDigit;
          
          // Security: Haptic feedback for better UX (optional)
          HapticFeedback.lightImpact();
          
          _logSecurityEvent('Digit added at position $i');
          return true;
        }
      }
      
      return false; // All slots full
      
    } catch (error) {
      ErrorHandler.logError('Add Digit', error);
      return false;
    }
  }

  // Security: Remove digit
  void removeDigit() {
    try {
      for (int i = code.length - 1; i >= 0; i--) {
        if (code[i].isNotEmpty) {
          code[i] = "";
          
          // Security: Haptic feedback
          HapticFeedback.lightImpact();
          
          _logSecurityEvent('Digit removed from position $i');
          break;
        }
      }
    } catch (error) {
      ErrorHandler.logError('Remove Digit', error);
    }
  }

  // Secure code verification
  Future<bool> verifyCode(String inputCode) async {
    try {
      // Security: Check lockout
      if (_isLocked) {
        _logSecurityEvent('Verification attempt while locked out');
        return false;
      }

      // Security: Validate input
      if (inputCode.isEmpty || inputCode.length != 4) {
        _logSecurityEvent('Invalid code length: ${inputCode.length}');
        return false;
      }

      if (!RegExp(r'^[0-9]{4}$').hasMatch(inputCode)) {
        _logSecurityEvent('Invalid code format: $inputCode');
        return false;
      }

      // Security: Rate limiting
      _attempts++;
      _lastAttemptTime = DateTime.now();
      await _saveAttemptHistory();

      if (_attempts >= _maxAttempts) {
        _isLocked = true;
        _startLockoutTimer();
        _logSecurityEvent('Account locked after $_attempts attempts');
        return false;
      }

      // Security: Simulate network delay (in real app, this would be API call)
      await Future.delayed(const Duration(seconds: 1));

      // Security: Constant-time comparison to prevent timing attacks
      final isValid = _constantTimeCompare(inputCode, serverCode);
      
      if (isValid) {
        // Security: Reset attempts on success
        _attempts = 0;
        await _saveAttemptHistory();
        _logSecurityEvent('Code verification successful');
      } else {
        _logSecurityEvent('Code verification failed - attempt $_attempts/$_maxAttempts');
      }
      
      return isValid;
      
    } catch (error) {
      ErrorHandler.logError('Verify Code', error);
      return false;
    }
  }

  // Security: Constant-time string comparison
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // Secure code resend
  void resendCode() {
    try {
      // Security: Check lockout
      if (_isLocked) {
        _logSecurityEvent('Resend attempt while locked out');
        return;
      }

      // Security: Generate new secure code
      serverCode = _generateSecureCode();
      
      // Security: Log resend event
      _logSecurityEvent('New code generated: ****');
      
      // Security: In production, send via secure channel (SMS, email, etc.)
      
    } catch (error) {
      ErrorHandler.logError('Resend Code', error);
    }
  }

  // Secure code validation
  String? validateCode() {
    try {
      final enteredCode = getEnteredCode();
      
      if (enteredCode.isEmpty) {
        return "Please enter the code";
      }
      
      if (enteredCode.length < 4) {
        return "Please enter all 4 digits";
      }
      
      if (!RegExp(r'^[0-9]{4}$').hasMatch(enteredCode)) {
        return "Invalid code format";
      }
      
      // Security: Check if locked
      if (_isLocked) {
        final remaining = _getRemainingLockoutTime();
        return "Too many attempts. Please try again in $remaining";
      }
      
      return null;
      
    } catch (error) {
      ErrorHandler.logError('Validate Code', error);
      return "Validation error";
    }
  }

  String _getRemainingLockoutTime() {
    if (_lastAttemptTime == null) return "0 minutes";
    
    final elapsed = DateTime.now().difference(_lastAttemptTime!);
    final remaining = _lockoutDuration - elapsed;
    
    if (remaining <= Duration.zero) return "0 minutes";
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return "$minutes minute${minutes > 1 ? 's' : ''}";
    } else {
      return "$seconds second${seconds > 1 ? 's' : ''}";
    }
  }

  bool isCodeComplete() {
    return code.every((digit) => digit.isNotEmpty);
  }

  String getEnteredCode() {
    return code.join();
  }

  // Security: Clear code
  void clearCode() {
    code = ["", "", "", ""];
    _logSecurityEvent('Code cleared');
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
    return codeUnit >= 48 && codeUnit <= 57; // 0-9
  }

  // Security: Get remaining attempts
  int getRemainingAttempts() {
    return _maxAttempts - _attempts;
  }

  // Security: Check if locked
  bool get isLocked => _isLocked;

  // Security: Get lockout time
  DateTime? get lockoutUntil {
    if (_lastAttemptTime == null) return null;
    return _lastAttemptTime!.add(_lockoutDuration);
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _logSecurityEvent('CodeLogic disposed');
    
  }

  void _logSecurityEvent(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final userId = _userId ?? 'unknown';
    
    // Security: Don't log actual codes
    final safeMessage = message
        .replaceAll(serverCode, '****')
        .replaceAll(getEnteredCode(), '****');
    
    final logMessage = 'CodeLogic[$timestamp][$userId]: $safeMessage';
    
    // In production, send to secure logging service
    print('🔒 AUTH SECURITY: $logMessage');
    
    // Store in secure storage
    _storeAuditLog(logMessage);
  }

  Future<void> _storeAuditLog(String message) async {
    try {
      final existingLogs = await SecureStorage.getData('auth_audit_logs') ?? '[]';
      final List<dynamic> logs = List<dynamic>.from(json.decode(existingLogs));
      
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'event': message,
        'userId': _userId,
      });
      
      // Keep only last 100 entries
      if (logs.length > 100) {
        logs.removeAt(0);
      }
      
      await SecureStorage.saveData('auth_audit_logs', json.encode(logs));
      
    } catch (error) {
      ErrorHandler.logError('Store Auth Audit Log', error);
    }
  }
}

