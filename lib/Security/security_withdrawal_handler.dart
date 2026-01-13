import 'dart:async';
import 'dart:convert';
import 'dart:math';

class WithdrawalSecurityHandler {
  // Private tracking
  static final List<String> _displayedReferences = [];
  static Timer? _cleanupTimer;
  static const Duration _cleanupInterval = Duration(minutes: 30);
  
  // Initialize security system
  static void initialize() {
    _startCleanupTimer();
  }
  
  // Validate reference number format and security
  static Map<String, dynamic> validateReference(String reference) {
    final List<String> issues = [];
    bool isValid = true;
    String securityLevel = 'medium';
    
    // 1. Basic format check
    if (reference.isEmpty || reference.length < 8) {
      isValid = false;
      issues.add('Reference too short');
    }
    
    if (reference.length > 50) {
      isValid = false;
      issues.add('Reference too long');
    }
    
    // 2. Pattern check (alphanumeric with optional dashes)
    final pattern = RegExp(r'^[A-Za-z0-9\-]{8,50}$');
    if (!pattern.hasMatch(reference)) {
      isValid = false;
      issues.add('Invalid characters in reference');
    }
    
    // 3. Check for suspicious patterns
    if (_containsSuspiciousPattern(reference)) {
      securityLevel = 'high';
      issues.add('Suspicious pattern detected');
    }
    
    // 4. Check for duplicate display attempts
    if (_displayedReferences.contains(reference)) {
      securityLevel = 'high';
      issues.add('Reference displayed multiple times');
    } else {
      _displayedReferences.add(reference);
    }
    
    final result = {
      'isValid': isValid,
      'issues': issues,
      'securityLevel': securityLevel,
    };
    
    // 5. Log security event
    _logSecurityEvent('reference_validation', {
      'reference': _maskReference(reference),
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return result;
  }
  
  // Validate amount for security
  static Map<String, dynamic> validateAmount(double amount) {
    final List<String> issues = [];
    bool isValid = true;
    String securityLevel = 'medium';
    
    const minAmount = 10.0;
    const maxAmount = 5000.0;
    
    // 1. Check bounds
    if (amount < minAmount) {
      isValid = false;
      issues.add('Below minimum withdrawal');
    }
    
    if (amount > maxAmount) {
      isValid = false;
      issues.add('Above maximum withdrawal');
    }
    
    // 2. Check for suspicious amounts
    if (_isSuspiciousAmount(amount)) {
      securityLevel = 'high';
      issues.add('Suspicious amount detected');
    }
    
    // 3. Check decimal places
    final amountStr = amount.toString();
    if (amountStr.contains('.') && amountStr.split('.')[1].length > 2) {
      securityLevel = 'high';
      issues.add('Excessive decimal places');
    }
    
    final result = {
      'isValid': isValid,
      'issues': issues,
      'securityLevel': securityLevel,
    };
    
    // 4. Log security event
    _logSecurityEvent('amount_validation', {
      'amount': amount,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return result;
  }
  
  // Generate secure reference number
  static String generateSecureReference() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Generate 4-character random string
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final randomPart = String.fromCharCodes(
      List.generate(4, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    
    // Generate numeric part
    final numericPart = (timestamp % 1000000).toString().padLeft(6, '0');
    
    // Format: WD-XXXX-YYYY
    final reference = 'WD-$randomPart-$numericPart';
    
    // Log generation
    _logSecurityEvent('reference_generated', {
      'reference': reference,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return reference;
  }
  
  // Track page access for security auditing
  static void trackPageAccess(String pageName, Map<String, dynamic> data) {
    _logSecurityEvent('page_access', {
      'page': pageName,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': _generateSessionId(),
    });
  }
  
  // Track page exit
  static void trackPageExit(String pageName, Map<String, dynamic> data) {
    _logSecurityEvent('page_exit', {
      'page': pageName,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'duration': data['duration_ms'] ?? 0,
    });
  }
  
  // Cleanup resources
  static void dispose() {
    _cleanupTimer?.cancel();
    _displayedReferences.clear();
  }
  
  // Private helper methods
  static bool _containsSuspiciousPattern(String reference) {
    final suspiciousPatterns = [
      'OR 1=1',
      'SELECT',
      'INSERT',
      'DELETE',
      'UPDATE',
      'DROP',
      'SCRIPT',
      'JAVASCRIPT',
      '<',
      '>',
      '&',
    ];
    
    final upperRef = reference.toUpperCase();
    return suspiciousPatterns.any((pattern) => upperRef.contains(pattern));
  }
  
  static bool _isSuspiciousAmount(double amount) {
    // Common fraud amounts
    final fraudAmounts = [999, 999.99, 9999, 9999.99, 10001, 50001];
    
    // Round number checks (except common ones)
    if (amount % 1000 == 0 && amount > 1000) {
      return true;
    }
    
    // Just below limits
    if (amount >= 4900 && amount <= 5000) {
      return true;
    }
    
    return fraudAmounts.contains(amount) || fraudAmounts.contains(amount.toInt());
  }
  
  static void _logSecurityEvent(String event, Map<String, dynamic> data) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'event': event,
      'data': data,
      'timestamp': timestamp,
      'level': 'security',
    };
    
    // In production, send to your logging service
    print(' SECURITY LOG: ${jsonEncode(logEntry)}');
  }
  
  static String _maskReference(String reference) {
    if (reference.length <= 8) return '***';
    return '${reference.substring(0, 3)}...${reference.substring(reference.length - 3)}';
  }
  
  static void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      // Cleanup old references when list gets too large
      if (_displayedReferences.length > 1000) {
        // Keep only the last 500 references
        final itemsToRemove = _displayedReferences.length - 500;
        if (itemsToRemove > 0) {
          _displayedReferences.removeRange(0, itemsToRemove);
        }
      }
    });
  }
  
  static String _generateSessionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sess_${timestamp}_${random.nextInt(1000000)}';
  }
  
  // Get security metrics
  static Map<String, dynamic> getSecurityMetrics() {
    return {
      'displayed_references_count': _displayedReferences.length,
      'cleanup_timer_active': _cleanupTimer?.isActive ?? false,
      'session_id': _generateSessionId(),
    };
  }
  
  // Clear all stored references (for testing or logout)
  static void clearAllReferences() {
    _displayedReferences.clear();
  }
  
  // Check if reference has been displayed recently
  static bool hasReferenceBeenDisplayed(String reference) {
    return _displayedReferences.contains(reference);
  }
  
  // Get list of all displayed references (masked for security)
  static List<String> getMaskedDisplayedReferences() {
    return _displayedReferences.map(_maskReference).toList();
  }
  
  // Simple validation wrapper for quick checks
  static bool isReferenceValid(String reference) {
    try {
      final validation = validateReference(reference);
      return validation['isValid'] == true;
    } catch (e) {
      return false;
    }
  }
  
  static bool isAmountValid(double amount) {
    try {
      final validation = validateAmount(amount);
      return validation['isValid'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // Reset the entire security system
  static void reset() {
    dispose();
    _displayedReferences.clear();
    _cleanupTimer = null;
  }
}
