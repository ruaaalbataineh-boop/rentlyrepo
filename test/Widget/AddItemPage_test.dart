import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';


void main() {
// 1

  testWidgets('Page UI loads ',
        (tester) async {

      await tester.pumpWidget(
        const MaterialApp(home: MockAddItemPage()),
      );

      expect(find.text('Add New Item'), findsOneWidget);
      expect(find.byKey(const Key('item_name')), findsOneWidget);
      expect(find.byKey(const Key('category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('submit_button')), findsOneWidget);
    },
  );

// 2
  testWidgets(' User can enter item name',
        (tester) async {

      await tester.pumpWidget(
        const MaterialApp(home: MockAddItemPage()),
      );

      await tester.enterText(
        find.byKey(const Key('item_name')),
        'Camera',
      );

      await tester.pump();

      expect(find.text('Camera'), findsOneWidget);
    },
  );

 // add rental
  testWidgets(' Rental period can be added',
        (tester) async {

      await tester.pumpWidget(
        const MaterialApp(home: MockAddItemPage()),
      );

      await tester.tap(find.byKey(const Key('add_period')));
      await tester.pump();

      expect(find.byKey(const Key('add_period')), findsOneWidget);
    },
  );

//
  testWidgets(' Submit without name shows error',
        (tester) async {

      await tester.pumpWidget(
        const MaterialApp(home: MockAddItemPage()),
      );

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Enter item name'), findsOneWidget);
    },

  );

}












class MockAddItemPage extends StatefulWidget {
  const MockAddItemPage({super.key});

  @override
  State<MockAddItemPage> createState() => _MockAddItemPageState();
}

class _MockAddItemPageState extends State<MockAddItemPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  String? selectedCategory;
  Map<String, double> rentalPeriods = {};

  void submit() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter item name")),
      );
      return;
    }
    if (rentalPeriods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add rental periods")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item submitted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('item_name'),
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              key: const Key('category_dropdown'),
              decoration: const InputDecoration(labelText: "Category"),
              items: const [
                DropdownMenuItem(value: "Electronics", child: Text("Electronics")),
                DropdownMenuItem(value: "Tools", child: Text("Tools")),
              ],
              onChanged: (val) => setState(() => selectedCategory = val),
            ),

            const SizedBox(height: 12),

            TextField(
              key: const Key('price_field'),
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),

            ElevatedButton(
              key: const Key('add_period'),
              onPressed: () {
                rentalPeriods["Daily"] = 10;
                setState(() {});
              },
              child: const Text("Add Rental Period"),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              key: const Key('submit_button'),
              onPressed: submit,
              child: const Text("Submit Item"),
            ),
          ],
        ),
      ),
    );
  }
}