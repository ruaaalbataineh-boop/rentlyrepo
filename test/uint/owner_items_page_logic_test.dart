import 'package:flutter_test/flutter_test.dart';
import 'package:p2/owner_listings.dart';

void main() {
  group('OwnerItemsPage Security - sanitizeString', () {
    test('Removes HTML and JS characters', () {
      final state = OwnerItemsPageState();

      final input = '<script>alert("x")</script>';
      final result = state.sanitizeString(input);

      expect(result.contains('<'), false);
      expect(result.contains('>'), false);
      expect(result.contains('"'), false);
      expect(result.contains("'"), false);
    });

    test('Trims spaces', () {
      final state = OwnerItemsPageState();

      final result = state.sanitizeString('   Test Item   ');
      expect(result, 'Test Item');
    });
  });
}
