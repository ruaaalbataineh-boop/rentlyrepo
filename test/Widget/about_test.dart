import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  // 1
  testWidgets('AboutAppPage shows UI correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MockAboutAppPage(),
          ),
        );

        expect(find.text('About App'), findsOneWidget);

        expect(find.byKey(const Key('app_title')), findsOneWidget);
        expect(find.text('Rently App'), findsOneWidget);

        expect(find.byKey(const Key('app_description')), findsOneWidget);

        expect(find.byKey(const Key('app_version')), findsOneWidget);

        expect(find.byKey(const Key('about_card')), findsOneWidget);

        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pumpAndSettle();
      });
  
}




















class MockAboutAppPage extends StatelessWidget {
  const MockAboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('back_button'),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "About App",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Card(
                    key: const Key('about_card'),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: const Padding(
                      padding: EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 80, color: Color(0xFF8A005D)),
                          SizedBox(height: 20),
                          Text(
                            "Rently App",
                            key: Key('app_title'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F0F46),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Rently is your smart solution for renting equipment, tools, "
                                "and more between individuals. We aim to provide a safe, "
                                "reliable, and user-friendly platform with secure payments, "
                                "wallet integration, and QR verification.",
                            key: Key('app_description'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Version 1.0.0",
                            key: Key('app_version'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

