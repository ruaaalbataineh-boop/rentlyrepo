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
      theme: ThemeData(
        primaryColor: const Color(0xFF1F0F46),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: const Color(0xFF8A005D),
        ),
      ),
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
  double balance = 1250.75;
  List<Map<String, dynamic>> activities = [
    {
      "icon": Icons.add_circle,
      "title": "Add Funds",
      "time": "2025-12-01 17:19",
      "amount": "+200.00",
      "color": Colors.green,
      "type": "deposit"
    },
    {
      "icon": Icons.remove_circle,
      "title": "Withdraw Balance",
      "time": "2025-12-01 17:19",
      "amount": "-100.00",
      "color": Colors.red,
      "type": "withdraw"
    },
    {
      "icon": Icons.remove_circle,
      "title": "Withdraw",
      "time": "2024-01-15 14:30",
      "amount": "-50.00",
      "color": Colors.red,
      "type": "withdraw"
    },
    {
      "icon": Icons.add_circle,
      "title": "Add Funds",
      "time": "2024-01-14 10:15",
      "amount": "+200.00",
      "color": Colors.green,
      "type": "deposit"
    },
    {
      "icon": Icons.shopping_cart,
      "title": "Equipment Rental",
      "time": "2024-01-13 16:45",
      "amount": "-75.50",
      "color": Colors.red,
      "type": "withdraw"
    },
  ];

  bool isWithdrawPressed = false;
  bool isAddPressed = false;

  void addActivity(String type, double amount) {
    setState(() {
      activities.insert(0, {
        "icon": type == "deposit" ? Icons.arrow_upward : Icons.arrow_downward,
        "title": type == "deposit" ? "Add Funds" : "Withdraw Balance",
        "time": "${DateTime.now()}".substring(0, 16),
        "amount": "${type == "deposit" ? "+" : "-"}\$${amount.toStringAsFixed(2)}",
        "color": type == "deposit" ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        "type": type,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: screenHeight * 0.06,
                bottom: screenHeight * 0.08,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "My Wallet",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Balance",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          "\$${balance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBalanceStat("Today", "+ \$25.50", Colors.green),
                            _buildBalanceStat("This Week", "- \$120.75", Colors.red),
                            _buildBalanceStat("This Month", "+ \$350.25", Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Color(0xFF1F0F46), size: 24),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Text(
                                "Recent Activity",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F0F46),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionHistoryPage(transactions: activities),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A005D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    "See All",
                                    style: TextStyle(
                                      color: Color(0xFF8A005D),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, color: Color(0xFF8A005D), size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    if (activities.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No activity yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Your transaction history will appear here",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: activities.take(5).map((item) => _buildActivityItem(item)).toList(),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F0F46),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.arrow_downward,
                            label: "Withdraw",
                            color: const Color(0xFFF44336),
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
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.arrow_upward,
                            label: "Add Funds",
                            color: const Color(0xFF4CAF50),
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
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics, color: Color(0xFF8A005D)),
                                SizedBox(width: 10),
                                Text(
                                  "Wallet Statistics",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F0F46),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCard("Total Deposits", "\$950.25", Icons.trending_up, const Color(0xFF4CAF50)),
                                _buildStatCard("Total Withdrawals", "\$300.50", Icons.trending_down, const Color(0xFFF44336)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String period, String amount, Color color) {
    return Column(
      children: [
        Text(
          period,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item["type"] == "deposit"
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : item["type"] == "payment"
                            ? const Color(0xFF8A005D).withOpacity(0.1)
                            : const Color(0xFFF44336).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item["icon"],
                    color: item["type"] == "deposit"
                        ? const Color(0xFF4CAF50)
                        : item["type"] == "payment"
                            ? const Color(0xFF8A005D)
                            : const Color(0xFFF44336),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1F0F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["time"],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item["amount"],
                  style: TextStyle(
                    color: item["color"],
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
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
        duration: const Duration(milliseconds: 150),
        transform: isPressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            if (isPressed)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionHistoryPage({super.key, required this.transactions});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String _selectedFilter = "All"; // "All", "Deposits", "Withdrawals"
  
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == "Deposits") {
      return widget.transactions.where((t) => t["amount"].toString().contains('+')).toList();
    } else if (_selectedFilter == "Withdrawals") {
      return widget.transactions.where((t) => t["amount"].toString().contains('-')).toList();
    } else {
      return widget.transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Transaction History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1F0F46),
        elevation: 0,
      ),
      body: Column(
        children: [
        
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1F0F46),
            child: Column(
              children: [
                _buildStatRow("Total", "\$1,250.75"),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Deposits", "\$950.25", const Color(0xFF4CAF50)),
                    _buildStatItem("Withdrawals", "\$300.50", const Color(0xFFF44336)),
                  ],
                ),
              ],
            ),
          ),
          
        
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterButton("All", _selectedFilter == "All", () {
                  setState(() {
                    _selectedFilter = "All";
                  });
                }),
                _buildFilterButton("Deposits", _selectedFilter == "Deposits", () {
                  setState(() {
                    _selectedFilter = "Deposits";
                  });
                }),
                _buildFilterButton("Withdrawals", _selectedFilter == "Withdrawals", () {
                  setState(() {
                    _selectedFilter = "Withdrawals";
                  });
                }),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),
          
        
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _selectedFilter == "All" 
            ? "All Deposits & Withdrawals" 
            : _selectedFilter == "Deposits" 
              ? "All Deposits" 
              : "All Withdrawals",
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.white, 
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Completed",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
),
          
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No ${_selectedFilter.toLowerCase()} transactions",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8A005D) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: const Color(0xFF8A005D), width: 2) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    bool isDeposit = transaction["amount"].toString().contains('+');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction["title"],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF1F0F46),
                ),
              ),
              Text(
                transaction["amount"],
                style: TextStyle(
                  color: isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            transaction["time"],
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "Completed",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WithdrawPage extends StatefulWidget {
  final double balance;

  const WithdrawPage({super.key, required this.balance});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController amountController = TextEditingController();
  int selectedPaymentMethod = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.06,
                bottom: MediaQuery.of(context).size.height * 0.06,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFFF44336)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Withdraw Funds",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 25),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.2), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Available Balance",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "\$${widget.balance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFF1F0F46),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickAmountButton("50"),
                              _buildQuickAmountButton("100"),
                              _buildQuickAmountButton("200"),
                              _buildQuickAmountButton("500"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter amount to withdraw",
                        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFF44336)),
                        suffixText: "USD",
                        suffixStyle: const TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.w600),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    const Text(
                      "Withdraw to:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F0F46),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => selectedPaymentMethod = 0),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 0 ? const Color(0xFFF44336).withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selectedPaymentMethod == 0 ? const Color(0xFFF44336) : Colors.grey[300]!,
                                width: selectedPaymentMethod == 0 ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedPaymentMethod == 0 ? const Color(0xFFF44336) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: selectedPaymentMethod == 0 ? Colors.white : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Credit/Debit Card",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedPaymentMethod == 0 ? FontWeight.w700 : FontWeight.w600,
                                          color: selectedPaymentMethod == 0 ? const Color(0xFFF44336) : const Color(0xFF1F0F46),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Visa, MasterCard",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedPaymentMethod == 0)
                                  const Icon(Icons.check_circle, color: Color(0xFFF44336), size: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        GestureDetector(
                          onTap: () => setState(() => selectedPaymentMethod = 1),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 1 ? const Color(0xFFF44336).withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selectedPaymentMethod == 1 ? const Color(0xFFF44336) : Colors.grey[300]!,
                                width: selectedPaymentMethod == 1 ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedPaymentMethod == 1 ? const Color(0xFFF44336) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: selectedPaymentMethod == 1 ? Colors.white : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Digital Wallet",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedPaymentMethod == 1 ? FontWeight.w700 : FontWeight.w600,
                                          color: selectedPaymentMethod == 1 ? const Color(0xFFF44336) : const Color(0xFF1F0F46),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Fast & secure transfers",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedPaymentMethod == 1)
                                  const Icon(Icons.check_circle, color: Color(0xFFF44336), size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Withdrawals may take 1-3 business days to process",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F0F46), Color(0xFFF44336)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF44336).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          double amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid amount"),
                                backgroundColor: Color(0xFFF44336),
                              ),
                            );
                            return;
                          }
                          if (amount > widget.balance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Amount exceeds your available balance"),
                                backgroundColor: Color(0xFFF44336),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            "newBalance": widget.balance - amount,
                            "amount": amount,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              "Withdraw \$${amountController.text.isNotEmpty ? double.parse(amountController.text).toStringAsFixed(2) : '0.00'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return GestureDetector(
      onTap: () => amountController.text = amount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)),
        ),
        child: Text(
          "\$$amount",
          style: const TextStyle(
            color: Color(0xFFF44336),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class DepositPage extends StatefulWidget {
  final double balance;

  const DepositPage({super.key, required this.balance});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController amountController = TextEditingController();
  int selectedPaymentMethod = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.06,
                bottom: MediaQuery.of(context).size.height * 0.06,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF4CAF50)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Add Funds",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 25),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Current Balance",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "\$${widget.balance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFF1F0F46),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickAmountButton("50"),
                              _buildQuickAmountButton("100"),
                              _buildQuickAmountButton("200"),
                              _buildQuickAmountButton("500"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter amount to deposit",
                        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4CAF50)),
                        suffixText: "USD",
                        suffixStyle: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      "Select payment method:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F0F46),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => selectedPaymentMethod = 0),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 0 ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selectedPaymentMethod == 0 ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                                width: selectedPaymentMethod == 0 ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedPaymentMethod == 0 ? const Color(0xFF4CAF50) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: selectedPaymentMethod == 0 ? Colors.white : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Credit/Debit Card",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedPaymentMethod == 0 ? FontWeight.w700 : FontWeight.w600,
                                          color: selectedPaymentMethod == 0 ? const Color(0xFF4CAF50) : const Color(0xFF1F0F46),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Visa, MasterCard, American Express",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedPaymentMethod == 0)
                                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        GestureDetector(
                          onTap: () => setState(() => selectedPaymentMethod = 1),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 1 ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selectedPaymentMethod == 1 ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                                width: selectedPaymentMethod == 1 ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedPaymentMethod == 1 ? const Color(0xFF4CAF50) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: selectedPaymentMethod == 1 ? Colors.white : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Digital Wallet",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedPaymentMethod == 1 ? FontWeight.w700 : FontWeight.w600,
                                          color: selectedPaymentMethod == 1 ? const Color(0xFF4CAF50) : const Color(0xFF1F0F46),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Fast & secure transfers",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedPaymentMethod == 1)
                                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, color: Color(0xFF4CAF50), size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Secure Payment",
                                style: TextStyle(
                                  color: Color(0xFF1F0F46),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your payment information is encrypted and secure. We use industry-standard SSL encryption.",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F0F46), Color(0xFF4CAF50)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          double amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid amount"),
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            "newBalance": widget.balance + amount,
                            "amount": amount,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              "Add \$${amountController.text.isNotEmpty ? double.parse(amountController.text).toStringAsFixed(2) : '0.00'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return GestureDetector(
      onTap: () => amountController.text = amount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Text(
          "\$$amount",
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ));
  }
}

class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 40;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width - radius, size.height - radius);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
  

