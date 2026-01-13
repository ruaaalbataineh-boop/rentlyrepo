import 'package:flutter/material.dart';
import 'package:p2/logic/transaction_history_logic.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/transaction_security.dart';

class TransactionHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  
  const TransactionHistoryPage({
    super.key,
    required this.transactions,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late TransactionHistoryLogic logic;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasAccess = false;
  Map<String, dynamic>? _dataIntegrityReport;

  @override
  void initState() {
    super.initState();
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

      _hasAccess = await TransactionSecurity.canAccessTransactions(
        userId, 
        widget.transactions,
      );

      if (!_hasAccess) {
        throw Exception('Access denied to transaction history');
      }

      
      logic = TransactionHistoryLogic(transactions: widget.transactions);

      
      await TransactionSecurity.logTransactionAccess(
        userId,
        widget.transactions,
        logic.filter,
      );

      
      _dataIntegrityReport = await logic.checkDataIntegrity();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Initialize Transaction Page', error);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorHandler.getSafeError(error);
        });
      }
    }
  }

  Widget _buildBalanceStats() {
    return StreamBuilder<Map<String, double>>(
      stream: FirestoreService.combinedWalletStream(UserManager.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingBalance();
        }

        if (snapshot.hasError) {
          return _buildErrorBalance(snapshot.error);
        }

        final balances = snapshot.data ?? {
          "userBalance": 0.0,
          "holdingBalance": 0.0
        };

        final currentBalance = balances["userBalance"] ?? 0.0;
        final holdingBalance = balances["holdingBalance"] ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${logic.formatBalance(currentBalance)}JD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Holding Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Holding',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${holdingBalance.toStringAsFixed(2)}JD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Total Deposits', logic.totalDeposits, Colors.green),
                  _buildStatItem('Total Withdrawals', logic.totalWithdrawals, Colors.orange),
                ],
              ),

              // Data Integrity Badge
              if (_dataIntegrityReport != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildDataIntegrityBadge(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorBalance(dynamic error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ErrorHandler.getSafeError(error),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataIntegrityBadge() {
    final integrityScore = _dataIntegrityReport?['dataIntegrityScore'] as double? ?? 0.0;
    final hasSuspiciousActivity = _dataIntegrityReport?['hasSuspiciousActivity'] == true;
    
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (hasSuspiciousActivity) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.warning;
      badgeText = 'Review Required';
    } else if (integrityScore >= 95) {
      badgeColor = Colors.green;
      badgeIcon = Icons.verified;
      badgeText = 'Data Verified';
    } else if (integrityScore >= 80) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.check_circle;
      badgeText = 'Data OK';
    } else {
      badgeColor = Colors.red;
      badgeIcon = Icons.error;
      badgeText = 'Data Issues';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton('All'),
          _buildFilterButton('Deposits'),
          _buildFilterButton('Withdrawals'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = logic.isFilterActive(text);
    
    return GestureDetector(
      onTap: () {
        try {
          setState(() {
            logic.setFilter(text);
          });
        } catch (error) {
          ErrorHandler.logError('Filter Button Tap', error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getSafeError(error)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8A005D) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ?  const Color(0xFF8A005D) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            logic.filterDisplayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F0F46),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8A005D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${logic.filteredTransactionCount} transactions',
              style: const TextStyle(
                color: Color(0xFF8A005D),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (!logic.hasFilteredTransactions()) {
      return _buildEmptyState();
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: logic.filteredTransactions.length,
        itemBuilder: (context, index) {
          try {
            final transaction = logic.filteredTransactions[index];
            return _buildTransactionItem(transaction);
          } catch (error) {
            ErrorHandler.logError('Build Transaction Item', error);
            return _buildErrorTransactionItem();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
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
              logic.filter == 'All'
                  ? 'No transactions yet'
                  : 'No ${logic.filter.toLowerCase()} transactions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    try {
      final isDeposit = transaction['type'] == 'deposit';
      final statusColor = logic.getStatusColor(transaction['status']);
      final typeColor = logic.getTypeColor(transaction['type']);
      final typeIcon = logic.getTypeIcon(transaction['type']);
      final typeDisplayName = logic.getTypeDisplayName(transaction['type']);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 15),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          typeDisplayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1F0F46),
                          ),
                        ),
                        Text(
                          '${isDeposit ? '+' : '-'}${logic.formatAmount(transaction['amount'] as double)}JD',
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      logic.formatDateTime(transaction['date'] as String, transaction['time'] as String),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction['method'].toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            logic.getStatusIcon(transaction['status']),
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction['status'].toString(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      ErrorHandler.logError('Build Transaction Item', error);
      return _buildErrorTransactionItem();
    }
  }

  Widget _buildErrorTransactionItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.error,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                'Unable to load transaction details',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
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
          '${logic.formatAmount(amount)}JD',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading transaction history...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
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
              _errorMessage ?? 'Failed to load transaction history',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 60,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You do not have permission to access this transaction history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : !_hasAccess
            ? _buildAccessDeniedScreen()
            : _errorMessage != null
              ? _buildErrorScreen()
              : Column(
                  children: [
                    _buildBalanceStats(),
                    _buildFilterButtons(),
                    _buildTransactionCounter(),
                    _buildTransactionList(),
                  ],
                ),
    );
  }
}
