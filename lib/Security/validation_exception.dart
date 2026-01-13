
class PaymentValidationException implements Exception {
  final String message;
  final String code;
  
  PaymentValidationException(this.message, {required this.code});
  
  @override
  String toString() => 'PaymentValidationException: $message';
}
