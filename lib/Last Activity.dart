import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rently Wallet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WalletPage(),
    );
  }
}


class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 500.0;
  List<Map<String, dynamic>> activities = [];

  bool isWithdrawPressed = false;
  bool isAddPressed = false;

  void addActivity(String type, double amount) {
    setState(() {
      activities.insert(0, {
        "icon": type == "deposit" ? Icons.arrow_upward : Icons.arrow_downward,
        "title": type == "deposit" ? "Add Funds" : "Withdraw Balance",
        "time": "${DateTime.now()}".substring(0, 16),
        "amount": "${type == "deposit" ? "+" : "-"}\$${amount.toStringAsFixed(2)}",
        "color": type == "deposit" ? Colors.green : Colors.red,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 60),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  "\$${balance.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

         
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Last Activity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LastActivityPage(activities: activities),
                      ),
                    );
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

         
          Expanded(
            child: activities.isEmpty
                ? const Center(child: Text("No activity yet."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final item = activities[index];
                      return _buildActivityItem(item);
                    },
                  ),
          ),

          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "Withdraw",
                    isPressed: isWithdrawPressed,
                    onTapDown: () => setState(() => isWithdrawPressed = true),
                    onTapCancel: () => setState(() => isWithdrawPressed = false),
                    onTapUp: () async {
                      setState(() => isWithdrawPressed = false);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WithdrawPage(balance: balance),
                        ),
                      );
                      if (result != null &&
                          result["newBalance"] != null &&
                          result["amount"] != null) {
                        setState(() => balance = result["newBalance"]);
                        addActivity("withdraw", result["amount"]);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    label: "Add Funds",
                    isPressed: isAddPressed,
                    onTapDown: () => setState(() => isAddPressed = true),
                    onTapCancel: () => setState(() => isAddPressed = false),
                    onTapUp: () async {
                      setState(() => isAddPressed = false);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DepositPage(balance: balance),
                        ),
                      );
                      if (result != null &&
                          result["newBalance"] != null &&
                          result["amount"] != null) {
                        setState(() => balance = result["newBalance"]);
                        addActivity("deposit", result["amount"]);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(item["icon"], color: Colors.black),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["title"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(item["time"],
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(item["amount"],
              style: TextStyle(
                  color: item["color"], fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapCancel,
    required VoidCallback onTapUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: isPressed
            ? Matrix4.translationValues(0, 3, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


class WithdrawPage extends StatelessWidget {
  final double balance;
  final TextEditingController amountController = TextEditingController();

  WithdrawPage({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw"),
        backgroundColor: const Color(0xFF1F0F46),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Your Balance: \$${balance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F0F46),
              ),
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid amount")),
                  );
                  return;
                }
                if (amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Amount exceeds balance")),
                  );
                  return;
                }
                Navigator.pop(context, {
                  "newBalance": balance - amount,
                  "amount": amount,
                });
              },
              child: const Text("Confirm Withdraw"),
            )
          ],
        ),
      ),
    );
  }
}


class DepositPage extends StatelessWidget {
  final double balance;
  final TextEditingController amountController = TextEditingController();

  DepositPage({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Funds"),
        backgroundColor: const Color(0xFF1F0F46),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Your Balance: \$${balance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F0F46),
              ),
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid amount")),
                  );
                  return;
                }
                Navigator.pop(context, {
                  "newBalance": balance + amount,
                  "amount": amount,
                });
              },
              child: const Text("Confirm Add"),
            )
          ],
        ),
      ),
    );
  }
}


class LastActivityPage extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  const LastActivityPage({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Last Activity"),
        backgroundColor: const Color(0xFF1F0F46),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final item = activities[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(item["icon"], color: Colors.black),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["title"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item["time"],
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(item["amount"],
                    style: TextStyle(
                        color: item["color"], fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }
}
  

