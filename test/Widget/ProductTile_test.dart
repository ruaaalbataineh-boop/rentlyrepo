import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  // 1
  testWidgets('ProductListPage shows products and search works',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MockProductListPage(),
          ),
        );

        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Product 3'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('search_field')), '2');
        await tester.pumpAndSettle();

        expect(find.text('Product 1'), findsNothing);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Product 3'), findsNothing);

        await tester.tap(find.byKey(const Key('product_Product 2')));

        await tester.pump();

        expect(find.text('Product 2 tapped!'), findsOneWidget);

      });

}








class MockProductListPage extends StatefulWidget {
  const MockProductListPage({super.key});

  @override
  State<MockProductListPage> createState() => _MockProductListPageState();
}

class _MockProductListPageState extends State<MockProductListPage> {
  final List<Map<String, dynamic>> mockProducts = [
    {
      "name": "Product 1",
      "description": "Description 1",
    },
    {
      "name": "Product 2",
      "description": "Description 2",
    },
    {
      "name": "Product 3",
      "description": "Description 3",
    },
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = mockProducts
        .where((p) =>
        p["name"]!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mock Product List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              key: const Key('search_field'),
              decoration: const InputDecoration(
                hintText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No products found!'))
                : ListView.builder(
              key: const Key('product_list'),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return ListTile(
                  key: Key('product_${product["name"]}'),
                  title: Text(product["name"]!),
                  subtitle: Text(product["description"]!),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        Text('${product["name"]} tapped!'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

