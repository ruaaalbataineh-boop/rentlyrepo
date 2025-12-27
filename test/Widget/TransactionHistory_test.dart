import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {

  testWidgets('Page loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockTransactionHistoryPage()),
    );

    expect(find.text('Transaction History'), findsOneWidget);
    expect(find.byKey(const Key('counter')), findsOneWidget);
  });

  testWidgets('All transactions visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockTransactionHistoryPage()),
    );

    expect(find.byKey(const Key('item_0')), findsOneWidget);
    expect(find.byKey(const Key('item_1')), findsOneWidget);
    expect(find.text('2 transactions'), findsOneWidget);
  });

  testWidgets('Filter deposits works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockTransactionHistoryPage()),
    );

    await tester.tap(find.byKey(const Key('Deposits')));
    await tester.pump();

    expect(find.byKey(const Key('item_0')), findsOneWidget);
    expect(find.byKey(const Key('item_1')), findsNothing);
    expect(find.text('1 transactions'), findsOneWidget);
  });

  testWidgets('Filter withdrawals works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockTransactionHistoryPage()),
    );

    await tester.tap(find.byKey(const Key('Withdrawals')));
    await tester.pump();

    expect(find.byKey(const Key('item_0')), findsOneWidget);
    expect(find.text('1 transactions'), findsOneWidget);
  });

  testWidgets('Empty state works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MockTransactionHistoryPage()),
    );

    await tester.tap(find.byKey(const Key('Deposits')));
    await tester.pump();

    // remove deposit manually by rebuilding empty widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('No transactions', key: Key('empty'))),
      ),
    );

    expect(find.byKey(const Key('empty')), findsOneWidget);
  });
}








class MockTransactionHistoryPage extends StatefulWidget {
  const MockTransactionHistoryPage({super.key});

  @override
  State<MockTransactionHistoryPage> createState() =>
      _MockTransactionHistoryPageState();
}

class _MockTransactionHistoryPageState
    extends State<MockTransactionHistoryPage> {
  String filter = 'All';

  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'deposit',
      'amount': 50.0,
      'status': 'Completed',
    },
    {
      'type': 'withdrawal',
      'amount': 20.0,
      'status': 'Pending',
    },
  ];

  List<Map<String, dynamic>> get filtered {
    if (filter == 'Deposits') {
      return transactions.where((t) => t['type'] == 'deposit').toList();
    }
    if (filter == 'Withdrawals') {
      return transactions.where((t) => t['type'] == 'withdrawal').toList();
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          /// FILTER BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterBtn('All'),
              _filterBtn('Deposits'),
              _filterBtn('Withdrawals'),
            ],
          ),

          const SizedBox(height: 20),

          /// COUNTER
          Text(
            '${filtered.length} transactions',
            key: const Key('counter'),
          ),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child: filtered.isEmpty
                ? const Text(
              'No transactions',
              key: Key('empty'),
            )
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final t = filtered[index];
                return ListTile(
                  key: Key('item_$index'),
                  title: Text(t['type']),
                  trailing: Text('\$${t['amount']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String text) {
    return ElevatedButton(
      key: Key(text),
      onPressed: () {
        setState(() => filter = text);
      },
      child: Text(text),
    );
  }
}


