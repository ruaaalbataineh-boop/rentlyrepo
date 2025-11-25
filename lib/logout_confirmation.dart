import 'package:flutter/material.dart';

class LogoutConfirmationPage extends StatefulWidget {
  const LogoutConfirmationPage({super.key});

  @override
  State<LogoutConfirmationPage> createState() => _LogoutConfirmationPageState();
}

class _LogoutConfirmationPageState extends State<LogoutConfirmationPage> {
  String selected = ""; 

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
              const Text(
                "Oh No!\nAre you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

            
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected == "cancel"
                      ? Colors.red
                      : Colors.grey[200],
                  foregroundColor: selected == "cancel"
                      ? Colors.white
                      : Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    selected = "cancel";
                  });
                  Navigator.pop(context); 
                },
                child: const Text("Cancel"),
              ),

              const SizedBox(height: 10),

              
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected == "logout"
                      ? Colors.red
                      : Colors.grey[200],
                  foregroundColor: selected == "logout"
                      ? Colors.white
                      : Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    selected = "logout";
                  });
                  
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: const Text("Yes, Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

