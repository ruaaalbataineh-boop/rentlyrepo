import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/setting_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingLogic logic;

  setUp(() {
    logic = SettingLogic();
  });

  group('Initial State', () {
    test('default values are false', () {
      expect(logic.muteNotifications, false);
      expect(logic.appAppearance, false);
    });
  });

  group('Local State Changes', () {
    test('changing values manually works', () {
      logic.muteNotifications = true;
      logic.appAppearance = true;

      expect(logic.muteNotifications, true);
      expect(logic.appAppearance, true);
    });
  });

  group('Get Settings Map', () {
    test('returns valid settings structure', () {
      final settings = logic.getSettings();

      expect(settings, isA<Map<String, bool>>());
      expect(settings.containsKey('muteNotifications'), true);
      expect(settings.containsKey('appAppearance'), true);
      expect(settings.containsKey('isAuthenticated'), true);
    });
  });
}
