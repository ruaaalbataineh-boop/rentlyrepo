
import 'package:flutter/material.dart';
import 'package:p2/EfawateercomInvoicePage.dart';
import 'package:p2/CreditCardPaymentPage.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'logic/wallet_recharge_logic.dart';


class WalletRechargePage extends StatefulWidget {
  const WalletRechargePage({super.key});

  @override
  State<WalletRechargePage> createState() => _WalletRechargePageState();
}

class _WalletRechargePageState extends State<WalletRechargePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedMethod;
  final TextEditingController amountController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final userId = UserManager.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text("You must be logged in."),
        ),
      );
    }

    return StreamBuilder<double>(
      stream: FirestoreService.walletBalanceStream(userId),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final currentBalance = snapshot.data ?? 0.0;

        final balanceStats = WalletRechargeLogic.getBalanceStats(currentBalance);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Recharge Wallet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          body: AbsorbPointer(
            absorbing: loading,
            child: Stack(
              children: [
                _buildBody(balanceStats, isLoading, currentBalance),
                if (loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(Map<String, String> balanceStats, bool isLoading, double currentBalance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildBalanceCard(balanceStats, currentBalance),
            const SizedBox(height: 25),
            _buildAmountInputCard(),
            const SizedBox(height: 20),
            _buildQuickAmountsCard(),
            const SizedBox(height: 25),
            _buildPaymentMethodsCard(),
            const SizedBox(height: 30),
            _buildContinueButton(),
            const SizedBox(height: 20),
            _buildImportantInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, String> stats, double currentBalance) {
    return Container(
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
            '${WalletRechargeLogic.formatBalance(currentBalance)}JD',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Card(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.add_circle, color: Color(0xFF8A005D)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter the amount you want to recharge',
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F0F46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              validator: WalletRechargeLogic.validateAmount, 
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
    );
  }

  Widget _buildQuickAmountsCard() {
    return Card(
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
              children: WalletRechargeLogic.quickAmounts.map((item) { 
                final colorHex = WalletRechargeLogic.getQuickAmountColor(item['color']);
                final color = Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
                
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
                          color,
                          color.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JD${item['amount']}',
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
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
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

            ...WalletRechargeLogic.paymentMethods.map((method) { 
              final isSelected = selectedMethod == method['id'];
              return _buildPaymentMethodItem(method, isSelected);
            }).toList(),

            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8A005D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8A005D).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Color(0xFF8A005D), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your payment is secure and encrypted',
                      style: TextStyle(
                        color: Color(0xFF8A005D),
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
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method['id'];
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: method['id'] == 'credit_card' ? 12 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8A005D).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8A005D)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8A005D)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconFromString(method['icon']),
                color: isSelected
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
                    method['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF8A005D)
                          : const Color(0xFF1F0F46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF8A005D), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final canProceed = WalletRechargeLogic.canProceedToPayment( 
      amountController.text,
      selectedMethod,
    );

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: canProceed
              ? const LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[400]!, Colors.grey[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: canProceed
              ? [
                  BoxShadow(
                    color: const Color(0xFF8A005D).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canProceed ? _handlePayment : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: canProceed ? Colors.white : Colors.grey[300],
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: canProceed ? Colors.white : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward,
                    color: canProceed ? Colors.white : Colors.grey[300],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportantInfo() {
    return Container(
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
          ...WalletRechargeLogic.importantInfo.map((info) => _buildInfoItem(info)), 
        ],
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
          const Icon(
            Icons.check_circle,
            color: Color(0xFF8A005D),
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
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.money;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'diamond':
        return Icons.diamond;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.money;
    }
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedMethod == null) return;

    final amount = WalletRechargeLogic.parseAmount(amountController.text);

    try {
      setState(() => loading = true);

      final invoice = await FirestoreService.createInvoice(
        amount,
        selectedMethod!, // "credit_card" or "efawateercom"
      );

      setState(() => loading = false);

      final ref = invoice["referenceNumber"];
      final method = invoice["method"];
      final clientSecret = invoice["clientSecret"];

      if (method == "credit_card") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditCardPaymentPage(
              amount: amount,
              referenceNumber: ref,
              clientSecret: clientSecret,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EfawateercomInvoicePage(
              amount: amount,
              referenceNumber: ref,
            ),
          ),
        );
      }

    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start payment process")),
      );
    }
  }
}
