import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850], 
      body: Center(
        child: Container(
          width: 350, 
          padding: const EdgeInsets.all(25), 
          decoration: BoxDecoration(
            color: Colors.grey[700], 
            borderRadius: BorderRadius.circular(25), 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Contact Us",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildSupportButton(FontAwesomeIcons.whatsapp, "WhatsApp", Colors.green),
                  buildSupportButton(FontAwesomeIcons.envelope, "Email", Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSupportButton(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14), 
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


