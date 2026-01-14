import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/wallet_logic.dart';

void main() {
  group('WalletLogic - Amount Validation', () {
    test('Valid amount returns true', () {
      expect(WalletLogic.isValidAmount(100), true);
    });

    test('Zero or negative amount returns false', () {
      expect(WalletLogic.isValidAmount(0), false);
      expect(WalletLogic.isValidAmount(-50), false);
    });
  });

  group('WalletLogic - Withdrawal', () {
    test('Can withdraw when balance is sufficient', () {
      expect(WalletLogic.canWithdraw(500, 200), true);
    });

    test('Cannot withdraw when balance is insufficient', () {
      expect(WalletLogic.canWithdraw(100, 200), false);
    });

    test('Cannot withdraw invalid amount', () {
      expect(WalletLogic.canWithdraw(500, -20), false);
    });
  });

  group('WalletLogic - Formatting', () {
   test('Format balance correctly', () {
  expect(WalletLogic.formatBalance(123.45), '123.45');
});


    test('Invalid balance formatted as 0.00', () {
      expect(WalletLogic.formatBalance(-5), '0.00');
    });

    test('Format amount with currency', () {
      expect(
        WalletLogic.formatAmountWithCurrency(50),
        '50.00 JD',
      );
    });
  });

  group('WalletLogic - Calculations', () {
    test('Calculate holding ratio correctly', () {
      final ratio = WalletLogic.calculateHoldingRatio(80, 20);
      expect(ratio, 20.0);
    });

    test('Holding ratio with zero total balance', () {
      expect(WalletLogic.calculateHoldingRatio(0, 0), 0.0);
    });

    test('Calculate fees for deposit', () {
      final fees = WalletLogic.calculateFees(100);
      expect(fees['fee'], 2.0); // 2%
      expect(fees['net_amount'], 98.0);
    });

    test('Calculate fees for withdrawal', () {
      final fees = WalletLogic.calculateFees(100, isDeposit: false);
      expect(fees['fee'], 1.5); // 1.5%
      expect(fees['net_amount'], 98.5);
    });
  });

  group('WalletLogic - Transactions', () {
    final transactions = [
      {
        'id': '1',
        'type': 'deposit',
        'amount': 100.0,
        'date': '2025-01-01',
        'time': '10:00',
        'method': 'Visa',
        'status': 'success',
        'is_valid': true,
      },
      {
        'id': '2',
        'type': 'withdrawal',
        'amount': 50.0,
        'date': '2025-01-02',
        'time': '12:00',
        'method': 'Cash',
        'status': 'success',
        'is_valid': true,
      },
    ];

    test('Get total deposits', () {
      final total = WalletLogic.getTotalDeposits(transactions);
      expect(total, 100.0);
    });

    test('Get total withdrawals', () {
      final total = WalletLogic.getTotalWithdrawals(transactions);
      expect(total, 50.0);
    });

    test('Get transaction count', () {
      final count = WalletLogic.getTransactionCount(transactions);
      expect(count, 2);
    });

    test('Filter by type - deposit', () {
      final result = WalletLogic.filterByType(transactions, 'deposit');
      expect(result.length, 1);
      expect(result.first['type'], 'deposit');
    });

    test('Sort by amount descending', () {
      final sorted = WalletLogic.sortByAmount(transactions);
      expect(sorted.first['amount'], 100.0);
    });
  });
}
