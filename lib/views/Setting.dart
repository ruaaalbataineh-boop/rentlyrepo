import 'package:flutter/material.dart';
import 'package:p2/views/AddItemPage.dart';
import 'package:p2/views/Chats_Page.dart';
import 'package:p2/WalletPage.dart';
import 'package:p2/app_theme.dart';
import 'Orders.dart';
import 'Categories_Page.dart';
import '../services/app_locale.dart';
import '../Support_and_Help.dart';
import '../logout_confirmation.dart';
import '../Personal Information.dart';
import 'Favourite.dart';
import '../about_app.dart';
import '../Remove Account.dart';
import '../widgets/bottom_nav.dart';
import 'package:p2/services/auth_service.dart'; 

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isSyncing = false;
  bool _muteNotifications = false;

  // App Appearance state
  bool _appAppearance = false;

  Future<void> _syncSettingsWithServer() async {
    setState(() {
      _isSyncing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings synced successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleToggleNotifications() async {
    setState(() {
      _muteNotifications = !_muteNotifications;
    });
  }

  // App Appearance toggle handler
 Future<void> _handleToggleAppearance() async {
  setState(() {
    _appAppearance = !_appAppearance;
  });

  AppTheme.toggleTheme(_appAppearance);
}

  Widget _buildHeader() {
    return ClipPath(
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocale.t('my_profile'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_isSyncing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Syncing...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
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
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
        return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('personal_info')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PersonalInfoPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('rently_wallet')),
                      onTap: () {
                        Navigator.pushNamed(context, WalletHomePage.routeName);
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.favorite,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('favourite')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const FavouritePage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child:
                            const Icon(Icons.info, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('about_app')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AboutAppPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.headset_mic,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('support_help')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SupportPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.language,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('app_language')),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Select Language"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title:
                                        const Text("English"),
                                    onTap: () {
                                      AppLocale.setLocale(
                                          const Locale('en'));
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text("عربي"),
                                    onTap: () {
                                      AppLocale.setLocale(
                                          const Locale('ar'));
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SwitchListTile(
                      value: _muteNotifications,
                      onChanged: (val) =>
                          _handleToggleNotifications(),
                      title:
                          const Text("Mute Notifications"),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                            Icons.notifications_off,
                            color: Colors.black),
                      ),
                    ),

                    // App Appearance
                    SwitchListTile(
                      value: _appAppearance,
                      onChanged: (val) =>
                          _handleToggleAppearance(),
                      title: const Text("App Appearance"),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.brightness_4,
                            color: Colors.black),
                      ),
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.delete_forever,
                            color: Colors.black),
                      ),
                      title:
                          Text(AppLocale.t('remove_account')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RemoveAccountPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      key: const ValueKey('settingsLogoutTile'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.logout,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('logout')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LogoutConfirmationPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          //bottomNavigationBar:
           //   const SharedBottomNav(currentIndex: 0),
        );
      },
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
    path.lineTo(size.width - radius,
        size.height - radius);
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
  bool shouldReclip(CustomClipper<Path> oldClipper) =>
      false;
}
