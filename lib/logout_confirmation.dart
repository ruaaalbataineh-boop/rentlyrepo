import 'package:flutter/material.dart';
import 'package:p2/logic/logout_confirmation_logic.dart';


class LogoutConfirmationPage extends StatefulWidget {
  const LogoutConfirmationPage({super.key});

  @override
  State<LogoutConfirmationPage> createState() => _LogoutConfirmationPageState();
}

class _LogoutConfirmationPageState extends State<LogoutConfirmationPage> {
  late LogoutConfirmationLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = LogoutConfirmationLogic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 60, color: Colors.black),
              const SizedBox(height: 10),
              Text(
                _logic.getDialogTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _logic.getButtonBackgroundColor("cancel", _logic.getSelectedOption()),
                  foregroundColor: _logic.getButtonTextColor("cancel", _logic.getSelectedOption()),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    _logic.selectOption("cancel");
                  });
                  Navigator.pop(context);
                },
                child: Text(_logic.getCancelButtonText()),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _logic.getButtonBackgroundColor("logout", _logic.getSelectedOption()),
                  foregroundColor: _logic.getButtonTextColor("logout", _logic.getSelectedOption()),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    _logic.selectOption("logout");
                  });
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: Text(_logic.getLogoutButtonText()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
