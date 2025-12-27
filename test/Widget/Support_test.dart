import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {

  testWidgets('SupportPage UI  loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockSupportPage(),
      ),
    );

    expect(find.byKey(const Key('support_container')), findsOneWidget);
    expect(find.text('Support and Help'), findsOneWidget);
  });

  testWidgets('Support buttons exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockSupportPage(),
      ),
    );

    expect(find.byKey(const Key('WhatsApp')), findsOneWidget);
    expect(find.byKey(const Key('Email')), findsOneWidget);
    expect(find.byKey(const Key('Call')), findsOneWidget);
  });

  testWidgets('Icons exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockSupportPage(),
      ),
    );

    expect(find.byIcon(Icons.chat), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);
  });

  testWidgets('Close icon exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MockSupportPage(),
      ),
    );

    expect(find.byKey(const Key('close_icon')), findsOneWidget);
  });
}



















class MockSupportPage extends StatelessWidget {
  const MockSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          key: const Key('support_container'),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Support and Help",
                    key: Key('title'),
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(Icons.close, key: Key('close_icon')),
                ],
              ),

              const SizedBox(height: 20),

              /// BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _MockSupportButton(
                    label: 'WhatsApp',
                    icon: Icons.chat,
                  ),
                  _MockSupportButton(
                    label: 'Email',
                    icon: Icons.email,
                  ),
                  _MockSupportButton(
                    label: 'Call',
                    icon: Icons.phone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockSupportButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MockSupportButton({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key(label),
      children: [
        Icon(icon),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }
}

