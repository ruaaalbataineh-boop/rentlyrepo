import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/logout_confirmation_logic.dart';

void main() {
  group('LogoutConfirmationLogic Tests', () {
    test('Initial selected option is empty', () {
      final logic = LogoutConfirmationLogic();
      expect(logic.getSelectedOption(), '');
    });

    test('selectOption updates selection', () {
      final logic = LogoutConfirmationLogic();
      logic.selectOption("cancel");
      expect(logic.getSelectedOption(), 'cancel');
      expect(logic.isCancelSelected(), true);
      expect(logic.isLogoutSelected(), false);
    });

    test('isCancelSelected returns correct value', () {
      final logic = LogoutConfirmationLogic();
      logic.selectOption("cancel");
      expect(logic.isCancelSelected(), true);
      logic.selectOption("logout");
      expect(logic.isCancelSelected(), false);
    });

    test('isLogoutSelected returns correct value', () {
      final logic = LogoutConfirmationLogic();
      logic.selectOption("logout");
      expect(logic.isLogoutSelected(), true);
      logic.selectOption("cancel");
      expect(logic.isLogoutSelected(), false);
    });

    test('getDialogTitle returns correct text', () {
      final logic = LogoutConfirmationLogic();
      expect(logic.getDialogTitle(), "Oh No!\nAre you sure you want to logout?");
    });

    test('getButtonTexts return correct text', () {
      final logic = LogoutConfirmationLogic();
      expect(logic.getCancelButtonText(), "Cancel");
      expect(logic.getLogoutButtonText(), "Yes, Logout");
    });

    test('getButtonBackgroundColor returns correct colors', () {
      final logic = LogoutConfirmationLogic();
      logic.selectOption("cancel");
      expect(logic.getButtonBackgroundColor("cancel", logic.getSelectedOption()), Colors.red);
      expect(logic.getButtonBackgroundColor("logout", logic.getSelectedOption()), isNot(Colors.red));
    });

    test('getButtonTextColor returns correct colors', () {
      final logic = LogoutConfirmationLogic();
      logic.selectOption("logout");
      expect(logic.getButtonTextColor("logout", logic.getSelectedOption()), Colors.white);
      expect(logic.getButtonTextColor("cancel", logic.getSelectedOption()), Colors.red);
    });
  });
}
