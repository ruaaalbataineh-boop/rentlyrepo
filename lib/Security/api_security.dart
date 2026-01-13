import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/error_handler.dart';

class ApiSecurity {
  static const String baseUrl = 'https://your-api.com';
  static const Duration timeout = Duration(seconds: 30);

  static Future<Map<String, String>> getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      String? token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        ErrorHandler.logSecurity('API Headers', 'No token available for authenticated request');
      }
    }
    
    return headers;
  }
  
  static Future<Map<String, dynamic>> securePost({
    required String endpoint,
    required Map<String, dynamic> data,
    String? token,
    bool requiresAuth = false,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await getHeaders(requiresAuth: requiresAuth);
      
      // إذا تم تمرير توكن مباشرة، نستخدمه
      if (token != null && token.isNotEmpty && requiresAuth) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // تنظيف البيانات
      final validatedData = _validateAndSanitizeData(data);
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(validatedData),
      ).timeout(timeout);
      
      return _handleResponse(response);
      
    } catch (error) {
      ErrorHandler.logError('API Post Request', error);
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> secureGet({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }
      
      final headers = await getHeaders(requiresAuth: requiresAuth);
      
      // إذا تم تمرير توكن مباشرة، نستخدمه
      if (token != null && token.isNotEmpty && requiresAuth) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(timeout);
      
      return _handleResponse(response);
      
    } catch (error) {
      ErrorHandler.logError('API Get Request', error);
      rethrow;
    }
  }
  
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true, 'data': null};
        }
        
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } catch (e) {
        ErrorHandler.logError('API Response Parsing', e);
        return {'success': true, 'data': response.body};
      }
    } else {
      ErrorHandler.logError('API Error Response', 
          'Status: ${response.statusCode}, Body: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');
      
      Map<String, dynamic>? errorData;
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'message': response.body};
      }
      
      return {
        'success': false,
        'error': errorData,
        'statusCode': response.statusCode,
      };
    }
  }
  
  static Map<String, dynamic> _validateAndSanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (var entry in data.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = _sanitizeString(entry.value as String);
      } else if (entry.value is Map) {
        sanitized[entry.key] = _validateAndSanitizeData(
          Map<String, dynamic>.from(entry.value as Map)
        );
      } else if (entry.value is List) {
        sanitized[entry.key] = _sanitizeList(entry.value as List);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }
  
  static String _sanitizeString(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('`', '&#x60;')
        .trim();
  }
  
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    final sanitized = <dynamic>[];
    
    for (var item in list) {
      if (item is String) {
        sanitized.add(_sanitizeString(item));
      } else if (item is Map) {
        sanitized.add(_validateAndSanitizeData(
          Map<String, dynamic>.from(item as Map)
        ));
      } else if (item is List) {
        sanitized.add(_sanitizeList(item as List));
      } else {
        sanitized.add(item);
      }
    }
    
    return sanitized;
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }
}
