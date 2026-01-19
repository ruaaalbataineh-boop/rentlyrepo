import 'package:flutter/material.dart';
import 'package:p2/CashWithdrawalPage.dart';
import 'package:p2/TransactionHistoryPage.dart';
import 'package:p2/WalletRechargePage.dart';
import 'package:p2/logic/wallet_logic.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/wallet_security.dart';

class WalletHomePage extends StatefulWidget {
  static const routeName = '/wallet';
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  late Stream<List<Map<String, dynamic>>> transactionsStream;
  late Stream<Map<String, double>> walletStream;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _walletSummary;

  @override
  void initState() {
    super.initState();

    final uid = UserManager.uid;

    if (uid != null) {
      transactionsStream = FirestoreService.userRecentTransactionsStream(uid);
      walletStream = FirestoreService.combinedWalletStream(uid);
    }

    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = UserManager.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

    
      await _logWalletAccess();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Initialize Wallet Page', error);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorHandler.getSafeError(error);
        });
      }
    }
  }

  Future<void> _logWalletAccess() async {
    try {
      
      await WalletSecurity.logWalletAccess(0.0);
    } catch (error) {
      ErrorHandler.logError('Log Wallet Access', error);
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F0F46),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Failed to load wallet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _initializePage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F0F46),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading wallet...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isLoading, double currentBalance, double holdingBalance) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A005D).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'TOTAL BALANCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLoading
                ? '...'
                : WalletLogic.formatBalance(currentBalance) + 'JD',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Holding: ${WalletLogic.formatBalance(holdingBalance)}JD",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          LinearProgressIndicator(
            value: WalletLogic.calculateHoldingRatio(currentBalance, holdingBalance) / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            '${WalletLogic.calculateHoldingRatio(currentBalance, holdingBalance).toStringAsFixed(1)}% of balance is holding',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Recharge Wallet',
            color: Colors.green,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletRechargePage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.money_off,
            label: 'Withdraw',
            color: Colors.orange,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashWithdrawalPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingTransactions();
        }

        if (snapshot.hasError) {
          return _buildErrorTransactions(snapshot.error);
        }

        final transactions = snapshot.data ?? [];

        
        final sanitizedTransactions = transactions.map(
          (tx) => WalletLogic.sanitizeTransaction(tx)
        ).where((tx) => tx['is_valid'] == true).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF1F0F46), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F0F46),
                        ),
                      ),
                    ],
                  ),
                
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${sanitizedTransactions.length}/${transactions.length} valid',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Secured and validated transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // EMPTY STATE
              if (sanitizedTransactions.isEmpty)
                _buildEmptyTransactions()
              else
                ...sanitizedTransactions.take(3).map((tx) => _buildTransactionItem(tx)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorTransactions(dynamic error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red,
          ),
          const SizedBox(height: 10),
          Text(
            ErrorHandler.getSafeError(error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          const Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All transactions are securely validated',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Color(0xFF8A005D),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F0F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildHelpItem(
            'How to recharge wallet?',
            'Step-by-step guide',
            Icons.add_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletRechargePage(),
                ),
              );
            },
          ),
          _buildHelpItem(
            'Withdrawal process',
            'Cash withdrawal instructions',
            Icons.money,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashWithdrawalPage(),
                ),
              );
            },
          ),
          _buildHelpItem(
            'Transaction issues',
            'Troubleshooting guide',
            Icons.error_outline,
            onTap: () {
              _showTroubleshootingGuide();
            },
          ),
          _buildHelpItem(
            'Security tips',
            'Keep your wallet safe',
            Icons.security,
            onTap: () {
              _showSecurityTips();
            },
          ),
        ],
      ),
    );
  }

  void _showTroubleshootingGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting Guide'),
        content: const SingleChildScrollView(
          child: Text(
            'Common issues and solutions:\n\n'
            '1. Pending transactions: Wait 24 hours\n'
            '2. Failed payments: Check your balance\n'
            '3. Incorrect amounts: Verify details\n'
            '4. Network issues: Check internet\n'
            '5. Delayed withdrawals: 1-2 business days\n'
            '6. Security alerts: Contact support\n'
            '7. Invalid transactions: Check validation\n'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecurityTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Security Tips'),
        content: const SingleChildScrollView(
          child: Text(
            'Keep your wallet secure:\n\n'
            '1. Never share your password\n'
            '2. Enable 2-factor authentication\n'
            '3. Check transaction details\n'
            '4. Report suspicious activity\n'
            '5. Use secure networks\n'
            '6. Keep app updated\n'
            '7. Log out on shared devices\n'
            '8. Monitor balance regularly\n'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        ErrorHandler.logInfo('Wallet Action', 'Clicked: $label');
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isDeposit = transaction['type'] == 'deposit';
    final isValid = transaction['is_valid'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showTransactionDetails(transaction);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Validation Badge
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isValid ? Icons.check : Icons.warning,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 10),
                // Transaction Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getColorFromString(transaction['color']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconFromString(transaction['icon']),
                    color: _getColorFromString(transaction['color']),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isDeposit ? 'Wallet Recharge' : 'Cash Withdrawal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1F0F46),
                              decoration: isValid ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '${isDeposit ? '+' : '-'}${(transaction['amount'] as double).toStringAsFixed(2)}JD',
                            style: TextStyle(
                              color: _getColorFromString(transaction['color']),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transaction['date']} • ${transaction['time']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction['method'],
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Invalid transaction',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
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
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final isValid = transaction['is_valid'] == true;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Security Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isValid ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isValid ? Icons.verified : Icons.warning,
                            size: 16,
                            color: isValid ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isValid ? 'Validated' : 'Invalid',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isValid ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _getColorFromString(transaction['color']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getIconFromString(transaction['icon']),
                        size: 40,
                        color: _getColorFromString(transaction['color']),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${transaction['type'] == 'deposit' ? '+' : '-'}${(transaction['amount'] as double).toStringAsFixed(2)}JD',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F0F46),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      transaction['type'] == 'deposit' ? 'Wallet Recharge' : 'Cash Withdrawal',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildDetailRow('Method', transaction['method']),
                    _buildDetailRow('Date', transaction['date']),
                    _buildDetailRow('Time', transaction['time']),
                    _buildDetailRow('Status', transaction['status']),
                    _buildDetailRow('Transaction ID', transaction['id']),
                    if (transaction.containsKey('sanitized_at'))
                      _buildDetailRow('Validated At', transaction['sanitized_at']),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A005D),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String subtitle, IconData icon, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF8A005D),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F0F46),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorFromString(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconFromString(String iconStr) {
    switch (iconStr.toLowerCase()) {
      case 'credit_card':
        return Icons.credit_card;
      case 'money':
        return Icons.money;
      case 'account_balance_wallet':
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'account_balance':
        return Icons.account_balance;
      case 'touch_app':
        return Icons.touch_app;
      case 'payments':
        return Icons.payments;
      case 'add_circle':
        return Icons.add_circle;
      case 'remove_circle':
        return Icons.remove_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    final userId = UserManager.uid;

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                "Authentication Required",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F0F46),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You must be logged in to view your wallet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<Map<String, double>>(
      stream: walletStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final balances = snapshot.data ?? {"userBalance": 0.0, "holdingBalance": 0.0};
        final currentBalance = balances["userBalance"] ?? 0.0;
        final holdingBalance = balances["holdingBalance"] ?? 0.0;

        // تحديث تسجيل الوصول عند تحميل الرصيد
        if (!isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WalletSecurity.logWalletAccess(currentBalance);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Wallet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
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
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.security, color: Colors.white),
                onPressed: _showSecurityTips,
                tooltip: 'Security Info',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(isLoading, currentBalance, holdingBalance),
                const SizedBox(height: 30),
                _buildActionButtons(),
                const SizedBox(height: 30),
                _buildRecentTransactions(),
                const SizedBox(height: 30),
                _buildHelpSection(),
                const SizedBox(height: 40),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Secured by Rently Wallet Protection',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
