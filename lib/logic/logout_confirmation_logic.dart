import 'dart:ui';

import 'package:flutter/material.dart';

class LogoutConfirmationLogic {
  String selectedOption = "";

  void selectOption(String option) {
    selectedOption = option;
  }

  String getSelectedOption() => selectedOption;

  bool isCancelSelected() => selectedOption == "cancel";
  bool isLogoutSelected() => selectedOption == "logout";

  String getDialogTitle() => "Oh No!\nAre you sure you want to logout?";
  String getCancelButtonText() => "Cancel";
  String getLogoutButtonText() => "Yes, Logout";

  Color getButtonBackgroundColor(String buttonType, String currentSelection) {
    return currentSelection == buttonType ? Colors.red : Colors.grey[200]!;
  }

  Color getButtonTextColor(String buttonType, String currentSelection) {
    return currentSelection == buttonType ? Colors.white : Colors.red;
  }
}
