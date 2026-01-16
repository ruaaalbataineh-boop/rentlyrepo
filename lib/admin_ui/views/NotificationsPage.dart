import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  String _recipient = "General";
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList('notifications');
    if (saved != null) {
      setState(() {
        _notifications =
            saved.map((e) => Map<String, String>.from(json.decode(e))).toList();
      });
    }
  }

  Future<void> saveNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toSave =
        _notifications.map((e) => json.encode(e)).toList();
    await prefs.setStringList('notifications', toSave);
  }

  void addNotification() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _notifications.insert(0, {
          "message": _messageController.text,
          "recipient": _recipient,
          "date": DateTime.now().toString().substring(0, 16),
        });
        _messageController.clear();
      });
      saveNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Notifications & Messages",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Notification Message",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            hintText: "Enter your notification...",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a message';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Recipients",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _recipient,
                          items: const [
                            DropdownMenuItem(
                                value: "General", child: Text("General")),
                            DropdownMenuItem(
                                value: "Specific",
                                child: Text("Specific User")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _recipient = value!;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F0F46),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: addNotification,
                            child: const Text(
                              "Send Notification",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Recent Notifications",
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._notifications.map((notif) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: ListTile(
                                title: Text(notif["message"] ?? ""),
                                subtitle: Text(
                                    "${notif["recipient"]} • ${notif["date"]}"),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
