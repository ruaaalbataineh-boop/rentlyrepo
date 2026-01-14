
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/transaction_history_logic.dart';

void main() {
  late TransactionHistoryLogic logic;

  setUp(() {
    final transactions = [
      {'id': '1', 'amount': 100.0, 'type': 'deposit', 'status': 'completed', 'date': '2026-01-14', 'time': '12:00', 'method': 'card'},
      {'id': '2', 'amount': 50, 'type': 'withdrawal', 'status': 'pending', 'date': '2026-01-13', 'time': '15:00', 'method': 'bank'},
    ];

    logic = TransactionHistoryLogic(transactions: transactions);
  });

  test('totalDeposits returns correct sum', () {
    expect(logic.totalDeposits, 100.0);
  });

  test('totalWithdrawals returns correct sum', () {
    expect(logic.totalWithdrawals, 50.0);
  });

  test('currentBalance calculates correctly', () {
    expect(logic.currentBalance, 50.0);
  });

  test('filter works correctly', () {
    logic.setFilter('Deposits');
    expect(logic.filteredTransactions.length, 1);
    expect(logic.filteredTransactions[0]['type'], 'deposit');
  });

  test('searchTransactions finds by ID', () {
    final result = logic.searchTransactions('1');
    expect(result.length, 1);
    expect(result[0]['id'], '1');
  });
}
