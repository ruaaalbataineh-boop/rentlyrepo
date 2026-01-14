import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/account_removal_logic.dart';
import 'package:mockito/mockito.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/api_security.dart';

class MockSecureStorage extends Mock implements SecureStorage {}
class MockApiSecurity extends Mock implements ApiSecurity {}

void main() {
  late MockSecureStorage mockStorage;
  late MockApiSecurity mockApi;

  setUp(() {
    mockStorage = MockSecureStorage();
    mockApi = MockApiSecurity();
  });

  test('Validate account removal returns false if user not authenticated', () async {
    
    final result = await AccountRemovalLogic.validateAccountRemoval();
    expect(result, false);
  });

  test('Get removal consequences returns default map on failure', () async {
    final result = await AccountRemovalLogic.getRemovalConsequences();
    expect(result['data_deleted'], true);
    expect(result['transactions_lost'], true);
    expect(result['cannot_undo'], true);
  });

  test('Verify invalid verification code returns false', () async {
    final result = await AccountRemovalLogic.confirmAccountRemoval('123');
    expect(result, false);
  });
}
