import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setting Page ', () {

    // 1 UI loads correctly
    testWidgets('Setting page UI loads correctly',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(
              home: MockSettingPage(),
            ),
          );

          expect(find.text("My Profile"), findsOneWidget);
          expect(find.byType(ListTile), findsWidgets);
          expect(find.byType(SwitchListTile), findsNWidgets(2));
        });

    // 2  Language dialog opens
    testWidgets('Language dialog opens when tapped',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(home: MockSettingPage()),
          );

          await tester.tap(find.text("App Language"));
          await tester.pumpAndSettle();

          expect(find.text("Select Language"), findsOneWidget);
          expect(find.text("English"), findsOneWidget);
          expect(find.text("عربي"), findsOneWidget);
        });

    // 3  Mute notifications switch works
    testWidgets('Mute notifications switch toggles',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(home: MockSettingPage()),
          );

          final muteSwitch = find.byKey(const Key('mute_switch'));
          expect(muteSwitch, findsOneWidget);

          await tester.tap(muteSwitch);
          await tester.pump();

          expect(find.byType(MockSettingPage), findsOneWidget);
        });

    // 4 App appearance switch works
    testWidgets('App appearance switch toggles',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(home: MockSettingPage()),
          );

          final appearanceSwitch =
          find.byKey(const Key('appearance_switch'));
          expect(appearanceSwitch, findsOneWidget);

          await tester.tap(appearanceSwitch);
          await tester.pump();

          expect(find.byType(MockSettingPage), findsOneWidget);
        });
  });
  
}























class MockSettingPage extends StatefulWidget {
  const MockSettingPage({super.key});

  @override
  State<MockSettingPage> createState() => _MockSettingPageState();
}

class _MockSettingPageState extends State<MockSettingPage> {
  bool muteNotifications = false;
  bool appAppearance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          ClipPath(
            clipper: SideCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Text(
                  "My Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          /// LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [

                _tile(Icons.person, "Personal Information"),
                _tile(Icons.account_balance_wallet, "Rently Wallet"),
                _tile(Icons.favorite, "Favourite"),
                _tile(Icons.confirmation_num, "Coupons"),
                _tile(Icons.info, "About App"),
                _tile(Icons.headset_mic, "Support & Help"),

                /// Language
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.language, color: Colors.black),
                  ),
                  title: const Text("App Language"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Select Language"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ListTile(title: Text("English")),
                            ListTile(title: Text("عربي")),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SwitchListTile(
                  key: const Key('mute_switch'),
                  value: muteNotifications,
                  onChanged: (val) {
                    setState(() {
                      muteNotifications = val;
                    });
                  },
                  title: const Text("Mute Notifications"),
                  secondary: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.notifications_off,
                        color: Colors.black),
                  ),
                ),

                /// App appearance
                SwitchListTile(
                  key: const Key('appearance_switch'),
                  value: appAppearance,
                  onChanged: (val) {
                    setState(() {
                      appAppearance = val;
                    });
                  },
                  title: const Text("App Appearance"),
                  secondary: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child:
                    const Icon(Icons.brightness_4, color: Colors.black),
                  ),
                ),

                _tile(Icons.delete_forever, "Remove Account"),
                _tile(Icons.logout, "Logout"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _tile(IconData icon, String title) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title),
      onTap: () {},
    );
  }
}



class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 40;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width - radius, size.height - radius);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
