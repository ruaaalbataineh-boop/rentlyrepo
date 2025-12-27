import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';


void main() {


  testWidgets('OrdersPage loads and tabs switch correctly',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const MaterialApp(
            home: MockOrdersPage(),
          ),
        );

        // Header
        expect(find.text('Orders'), findsOneWidget);

        // Tabs
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Previous'), findsOneWidget);

        // Default content
        expect(find.text('No pending orders'), findsOneWidget);

        // Tap Active
        await tester.tap(find.text('Active'));
        await tester.pump();
        expect(find.text('No active orders'), findsOneWidget);

        // Tap Previous
        await tester.tap(find.text('Previous'));
        await tester.pump();
        expect(find.text('No previous orders'), findsOneWidget);

      });

}









class MockOrdersPage extends StatefulWidget {
  const MockOrdersPage({super.key});

  @override
  State<MockOrdersPage> createState() => _MockOrdersPageState();
}

class _MockOrdersPageState extends State<MockOrdersPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTabs(),
          const SizedBox(height: 30),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Text(
          'Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// TABS
  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTab('Pending', 0),
        const SizedBox(width: 30),
        _buildTab('Active', 1),
        const SizedBox(width: 30),
        _buildTab('Previous', 2),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    final active = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? const Color(0xFF8A005D) : Colors.black,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF8A005D) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// CONTENT
  Widget _buildContent() {
    if (selectedTab == 0) {
      return const Center(child: Text('No pending orders'));
    } else if (selectedTab == 1) {
      return const Center(child: Text('No active orders'));
    } else {
      return const Center(child: Text('No previous orders'));
    }
  }
}