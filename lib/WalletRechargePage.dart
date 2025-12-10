import 'package:flutter/material.dart';
import 'package:p2/ClickPaymentPage.dart';
import 'package:p2/CreditCardPaymentPage.dart';


class WalletRechargePage extends StatefulWidget {
  const WalletRechargePage({super.key});

  @override
  State<WalletRechargePage> createState() => _WalletRechargePageState();
}

class _WalletRechargePageState extends State<WalletRechargePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String selectedMethod = 'Credit Card';
  final TextEditingController amountController = TextEditingController();
  double currentBalance = 1250.75;

  final List<Map<String, dynamic>> quickAmounts = [
    {'amount': '50', 'icon': Icons.attach_money, 'color': Colors.green},
    {'amount': '100', 'icon': Icons.money, 'color': Colors.blue},
    {'amount': '200', 'icon': Icons.account_balance_wallet, 'color': Colors.orange},
    {'amount': '500', 'icon': Icons.savings, 'color': Colors.purple},
    {'amount': '1000', 'icon': Icons.diamond, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharge Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الرصيد الحالي
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A005D).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'CURRENT BALANCE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('Today', '+ \$25.50', Colors.green),
                          _buildMiniStat('This Week', '+ \$350.25', Colors.green),
                          _buildMiniStat('Last Month', '+ \$1,200.00', Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // قسم إدخال المبلغ
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_circle, color: Color(0xFF8A005D)),
                          SizedBox(width: 10),
                          Text(
                            'Enter Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter valid amount';
                          }
                          if (amount < 10) {
                            return 'Minimum amount is \$10';
                          }
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F0F46),
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 28,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w700,
                          ),
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF8A005D),
                            size: 28,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // مبالغ سريعة
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flash_on, color: Color(0xFF8A005D)),
                          SizedBox(width: 10),
                          Text(
                            'Quick Amounts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: quickAmounts.map((item) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                amountController.text = item['amount'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    item['color'] as Color,
                                    (item['color'] as Color).withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (item['color'] as Color).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${item['amount']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // اختيار طريقة الدفع
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payment, color: Color(0xFF8A005D)),
                          SizedBox(width: 10),
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 15),

                      // بطاقة الائتمان
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMethod = 'Credit Card';
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selectedMethod == 'Credit Card'
                                ? const Color(0xFF8A005D).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedMethod == 'Credit Card'
                                  ? const Color(0xFF8A005D)
                                  : Colors.grey[300]!,
                              width: selectedMethod == 'Credit Card' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedMethod == 'Credit Card'
                                      ? const Color(0xFF8A005D)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.credit_card,
                                  color: selectedMethod == 'Credit Card'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Credit/Debit Card',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedMethod == 'Credit Card'
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: selectedMethod == 'Credit Card'
                                            ? const Color(0xFF8A005D)
                                            : const Color(0xFF1F0F46),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Visa, MasterCard, American Express',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedMethod == 'Credit Card')
                                const Icon(Icons.check_circle, color: Color(0xFF8A005D), size: 24),
                            ],
                          ),
                        ),
                      ),

                      // Click
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMethod = 'Click';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selectedMethod == 'Click'
                                ? const Color(0xFF8A005D).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedMethod == 'Click'
                                  ? const Color(0xFF8A005D)
                                  : Colors.grey[300]!,
                              width: selectedMethod == 'Click' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedMethod == 'Click'
                                      ? const Color(0xFF8A005D)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: selectedMethod == 'Click'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Click',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedMethod == 'Click'
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: selectedMethod == 'Click'
                                            ? const Color(0xFF8A005D)
                                            : const Color(0xFF1F0F46),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Digital wallet payment',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedMethod == 'Click')
                                const Icon(Icons.check_circle, color: Color(0xFF8A005D), size: 24),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, color: Colors.blue, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your payment is secure and encrypted',
                                style: TextStyle(
                                  color: Colors.blue[800]!,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // زر الاستمرار
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handlePayment,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // معلومات إضافية
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Important Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F0F46),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('Minimum recharge amount: \$10'),
                    _buildInfoItem('No transaction fees'),
                    _buildInfoItem('Funds available instantly'),
                    _buildInfoItem('24/7 customer support'),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String period, String amount, Color color) {
    return Column(
      children: [
        Text(
          period,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      )
    );
  }

  void _handlePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount < 10) {
      return;
    }

    if (selectedMethod == 'Credit Card') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreditCardPaymentPage(amount: amount),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClickPaymentPage(amount: amount),
        ),
      );
    }
  }
}
