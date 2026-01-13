import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/api_security.dart';
import 'package:p2/security/route_guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LogoutConfirmationLogic {
  String selectedOption = "";
  bool _isInitialized = false;
  DateTime? _lastLogoutAttempt;
  final Duration _logoutCooldown = const Duration(seconds: 30);
  int _logoutAttempts = 0;
  final int _maxLogoutAttempts = 3;
  String? _currentUserId;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> initialize() async {
    try {
      // Security: Validate that user is authenticated
      if (!RouteGuard.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      // Get current user ID
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      _currentUserId = user.uid;

      // Load logout history
      await _loadLogoutHistory();
      
      _isInitialized = true;
      ErrorHandler.logInfo('LogoutConfirmationLogic', 'Initialized successfully');
      
    } catch (error) {
      ErrorHandler.logError('LogoutConfirmationLogic Initialization', error);
    }
  }

  Future<void> _loadLogoutHistory() async {
    try {
      final history = await SecureStorage.getData('logout_attempts_$_currentUserId');
      if (history != null) {
        _logoutAttempts = int.tryParse(history) ?? 0;
      }
      
      final lastAttempt = await SecureStorage.getData('last_logout_attempt_$_currentUserId');
      if (lastAttempt != null) {
        _lastLogoutAttempt = DateTime.parse(lastAttempt);
        
        // Reset if cooldown period has passed
        if (_lastLogoutAttempt != null && 
            DateTime.now().difference(_lastLogoutAttempt!) > _logoutCooldown) {
          _logoutAttempts = 0;
          await _saveLogoutHistory();
        }
      }
    } catch (error) {
      ErrorHandler.logError('Load Logout History', error);
    }
  }

  Future<void> _saveLogoutHistory() async {
    try {
      await SecureStorage.saveData(
        'logout_attempts_$_currentUserId',
        _logoutAttempts.toString(),
      );
      if (_lastLogoutAttempt != null) {
        await SecureStorage.saveData(
          'last_logout_attempt_$_currentUserId',
          _lastLogoutAttempt!.toIso8601String(),
        );
      }
    } catch (error) {
      ErrorHandler.logError('Save Logout History', error);
    }
  }

  Future<void> _recordLogoutAttempt() async {
    _logoutAttempts++;
    _lastLogoutAttempt = DateTime.now();
    await _saveLogoutHistory();
    
    ErrorHandler.logSecurity('LogoutConfirmationLogic', 
        'Logout attempt recorded - Total: $_logoutAttempts');
  }

  bool get isOnCooldown => _lastLogoutAttempt != null && 
      DateTime.now().difference(_lastLogoutAttempt!) < _logoutCooldown;
  
  bool get hasExceededAttempts => _logoutAttempts >= _maxLogoutAttempts;

  String get remainingCooldown {
    if (_lastLogoutAttempt == null || !isOnCooldown) return "";
    final remaining = _logoutCooldown - DateTime.now().difference(_lastLogoutAttempt!);
    final seconds = remaining.inSeconds;
    return seconds > 0 ? "$seconds seconds" : "a moment";
  }

  void selectOption(String option) {
    try {
      // Security: Validate option
      if (!['cancel', 'logout'].contains(option)) {
        ErrorHandler.logError('Select Option', 'Invalid option: $option');
        return;
      }

      selectedOption = option;
      
      if (option == "logout") {
        _recordLogoutAttempt();
        
        if (hasExceededAttempts) {
          ErrorHandler.logSecurity('LogoutConfirmationLogic', 
              'Logout attempts exceeded for user: $_currentUserId');
        }
      }
      
      ErrorHandler.logInfo('LogoutConfirmationLogic', 'Option selected: $option');
      
    } catch (error) {
      ErrorHandler.logError('Select Option', error);
    }
  }

  String getSelectedOption() => selectedOption;

  bool isCancelSelected() => selectedOption == "cancel";
  bool isLogoutSelected() => selectedOption == "logout";

  String getDialogTitle() {
    try {
      if (!_isInitialized) {
        return "Please wait...";
      }

      if (hasExceededAttempts) {
        return "Too many logout attempts.\nPlease wait $remainingCooldown.";
      }

      if (isOnCooldown) {
        return "Please wait $remainingCooldown\nbefore logging out again.";
      }

      return "Oh No!\nAre you sure you want to logout?";
    } catch (error) {
      ErrorHandler.logError('Get Dialog Title', error);
      return "Confirmation Required";
    }
  }

  String getCancelButtonText() {
    try {
      if (!_isInitialized) return "Loading...";
      return "Cancel";
    } catch (error) {
      ErrorHandler.logError('Get Cancel Button Text', error);
      return "Cancel";
    }
  }

  String getLogoutButtonText() {
    try {
      if (!_isInitialized) return "Loading...";
      
      if (hasExceededAttempts) {
        return "Too Many Attempts";
      }

      if (isOnCooldown) {
        return "Wait $remainingCooldown";
      }

      return "Yes, Logout";
    } catch (error) {
      ErrorHandler.logError('Get Logout Button Text', error);
      return "Logout";
    }
  }

  Color getButtonBackgroundColor(String buttonType, String currentSelection) {
    try {
      // Security: Validate inputs
      if (!['cancel', 'logout'].contains(buttonType)) {
        return Colors.grey[200]!;
      }

      if (buttonType == "logout") {
        if (hasExceededAttempts || isOnCooldown) {
          return Colors.grey[400]!;
        }
      }

      return currentSelection == buttonType ? Colors.red : Colors.grey[200]!;
    } catch (error) {
      ErrorHandler.logError('Get Button Background Color', error);
      return Colors.grey[200]!;
    }
  }

  Color getButtonTextColor(String buttonType, String currentSelection) {
    try {
      // Security: Validate inputs
      if (!['cancel', 'logout'].contains(buttonType)) {
        return Colors.red;
      }

      if (buttonType == "logout") {
        if (hasExceededAttempts || isOnCooldown) {
          return Colors.grey[600]!;
        }
      }

      return currentSelection == buttonType ? Colors.white : Colors.red;
    } catch (error) {
      ErrorHandler.logError('Get Button Text Color', error);
      return Colors.red;
    }
  }

  // Security: Perform secure logout
  Future<Map<String, dynamic>> performSecureLogout() async {
    try {
      if (!_isInitialized) {
        throw Exception('Logic not initialized');
      }

      if (hasExceededAttempts) {
        throw Exception('Too many logout attempts. Please wait $remainingCooldown.');
      }

      if (isOnCooldown) {
        throw Exception('Please wait $remainingCooldown before logging out again.');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Record logout attempt
      await _recordLogoutAttempt();

      // Update user status in database
      try {
        final userRef = _database.ref("users/${user.uid}");
        await userRef.update({
          "status": "offline",
          "lastSeen": DateTime.now().millisecondsSinceEpoch,
          "lastLogout": DateTime.now().millisecondsSinceEpoch,
        }).timeout(const Duration(seconds: 10));
      } catch (e) {
        ErrorHandler.logError('Update User Status', e);
        // Continue even if database update fails
      }

      // Clear secure storage
      await SecureStorage.clearAll();

      // Sign out from Firebase
      await _auth.signOut();

      // Reset local state
      selectedOption = "";
      _logoutAttempts = 0;
      _lastLogoutAttempt = null;
      await _saveLogoutHistory();

      ErrorHandler.logSecurity('LogoutConfirmationLogic', 
          'User ${user.uid} logged out successfully');

      return {
        'success': true,
        'message': 'Logged out successfully',
        'userId': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (error) {
      ErrorHandler.logError('Perform Secure Logout', error);
      return {
        'success': false,
        'error': ErrorHandler.getSafeError(error),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Security: Get logout attempt status
  Future<Map<String, dynamic>> getLogoutAttemptStatus() async {
    try {
      return {
        'attempts': _logoutAttempts,
        'maxAttempts': _maxLogoutAttempts,
        'isOnCooldown': isOnCooldown,
        'hasExceededAttempts': hasExceededAttempts,
        'cooldownRemaining': remainingCooldown,
        'lastAttempt': _lastLogoutAttempt?.toIso8601String(),
        'isInitialized': _isInitialized,
      };
    } catch (error) {
      ErrorHandler.logError('Get Logout Attempt Status', error);
      return {
        'attempts': 0,
        'maxAttempts': _maxLogoutAttempts,
        'isOnCooldown': false,
        'hasExceededAttempts': false,
        'cooldownRemaining': '',
        'lastAttempt': null,
        'isInitialized': false,
      };
    }
  }

  // Security: Check if logout is allowed
  bool isLogoutAllowed() {
    try {
      if (!_isInitialized) return false;
      if (hasExceededAttempts) return false;
      if (isOnCooldown) return false;
      return true;
    } catch (error) {
      ErrorHandler.logError('Is Logout Allowed', error);
      return false;
    }
  }

  // Security: Reset logout attempts (for admin or manual override)
  Future<void> resetLogoutAttempts() async {
    try {
      _logoutAttempts = 0;
      _lastLogoutAttempt = null;
      await _saveLogoutHistory();
      
      ErrorHandler.logSecurity('LogoutConfirmationLogic', 
          'Logout attempts reset for user: $_currentUserId');
    } catch (error) {
      ErrorHandler.logError('Reset Logout Attempts', error);
    }
  }

  // Security: Cleanup resources
  void cleanupResources() {
    try {
      selectedOption = "";
      _currentUserId = null;
      
      ErrorHandler.logInfo('LogoutConfirmationLogic', 'Resources cleaned up');
    } catch (error) {
      ErrorHandler.logError('Cleanup Resources', error);
    }
  }
}
