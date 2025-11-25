// import 'package:flutter/material.dart';
// import 'package:p2/Chats_Page.dart';
// import 'package:p2/PaymentPage.dart';
// import 'Orders.dart';
// import 'Categories_Page.dart';
// import 'app_locale.dart';
// import 'Support_and_Help.dart'; 
// import 'logout_confirmation.dart'; 


// import 'Personal Information.dart';
// import 'Favourite.dart';
// import 'Coupons.dart';
// import 'About App.dart';
// import 'Remove Account.dart';

// class SettingPage extends StatefulWidget {
//   const SettingPage({super.key});

//   @override
//   State<SettingPage> createState() => _SettingPageState();
// }

// class _SettingPageState extends State<SettingPage> {
//   bool muteNotifications = false;
//   bool appAppearance = false;
//   int selectedBottom = 0; 

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder(
//       valueListenable: AppLocale.locale,
//       builder: (context, locale, child) {
//         return Scaffold(
//           backgroundColor: Colors.white,
//           body: Column(
//             children: [
            
//               ClipPath(
//                 clipper: SideCurveClipper(),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.only(top: 50, bottom: 60),
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       AppLocale.t('my_profile'),
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

              
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   children: [
                  
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.person, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('personal_info')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const PersonalInfoPage()),
//                         );
//                       },
//                     ),

                    
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.account_balance_wallet,
//                             color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('rently_wallet')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const PaymentPage()),
//                         );
//                       },
//                     ),

                    
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.favorite, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('favourite')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const FavouritePage()),
//                         );
//                       },
//                     ),

                    
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.confirmation_num,
//                             color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('coupons')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const CouponsPage()),
//                         );
//                       },
//                     ),

                  
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.info, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('about_app')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const AboutAppPage()),
//                         );
//                       },
//                     ),

                    
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.headset_mic, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('support_help')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => const SupportPage()),
//                         );
//                       },
//                     ),

                    
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.language, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('app_language')),
//                       onTap: () {
//                         showDialog(
//                           context: context,
//                           builder: (context) {
//                             return AlertDialog(
//                               title: const Text("Select Language"),
//                               content: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   ListTile(
//                                     title: const Text("English"),
//                                     onTap: () {
//                                       AppLocale.setLocale(const Locale('en'));
//                                       Navigator.pop(context);
//                                     },
//                                   ),
//                                   ListTile(
//                                     title: const Text("عربي"),
//                                     onTap: () {
//                                       AppLocale.setLocale(const Locale('ar'));
//                                       Navigator.pop(context);
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),

                    
//                     SwitchListTile(
//                       value: muteNotifications,
//                       onChanged: (val) {
//                         setState(() {
//                           muteNotifications = val;
//                         });
//                       },
//                       title: const Text("Mute Notifications"),
//                       secondary: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.notifications_off,
//                             color: Colors.black),
//                       ),
//                     ),

                   
//                     SwitchListTile(
//                       value: appAppearance,
//                       onChanged: (val) {
//                         setState(() {
//                           appAppearance = val;
//                         });
//                       },
//                       title: const Text("App Appearance"),
//                       secondary: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child:
//                             const Icon(Icons.brightness_4, color: Colors.black),
//                       ),
//                     ),

                  
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child:
//                             const Icon(Icons.delete_forever, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('remove_account')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const RemoveAccountPage()),
//                         );
//                       },
//                     ),

                   
//                     ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.grey[300],
//                         child: const Icon(Icons.logout, color: Colors.black),
//                       ),
//                       title: Text(AppLocale.t('logout')),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) =>
//                                   const LogoutConfirmationPage()),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           bottomNavigationBar: Container(
//             height: 70,
//             decoration: const BoxDecoration(
//               color: Color(0xFF1B2230),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(25),
//                 topRight: Radius.circular(25),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 buildBottomIcon(Icons.settings, 0),
//                 buildBottomIcon(Icons.inventory_2_outlined, 1),
//                 buildBottomIcon(Icons.add, 2),
//                 buildBottomIcon(Icons.chat_bubble_outline, 3),
//                 buildBottomIcon(Icons.home_outlined, 4),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

  
//   Widget buildBottomIcon(IconData icon, int index) {
//     bool active = selectedBottom == index;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedBottom = index;
//         });

      
//         if (index == 0) {
          
//         } else if (index == 1) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const OrdersPage()),
//           );
//         } else if (index == 3) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const ChatsPage()),
//           );
//         } else if (index == 4) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const CategoryPage()),
//           );
//         }
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOut,
//         margin: EdgeInsets.only(bottom: active ? 8 : 0),
//         padding: const EdgeInsets.all(12),
//         decoration: active
//             ? BoxDecoration(
//                 color: Colors.grey[300],
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.15),
//                     blurRadius: 6,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               )
//             : null,
//         child: Icon(
//           icon,
//           size: active ? 32 : 26,
//           color: active ? Colors.black : Colors.white70,
//         ),
//       ),
//     );
//   }
// }

// class SideCurveClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     double radius = 40;
//     Path path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(0, size.height);
//     path.arcToPoint(
//       Offset(radius, size.height - radius),
//       radius: Radius.circular(radius),
//       clockwise: true,
//     );
//     path.lineTo(size.width - radius, size.height - radius);
//     path.arcToPoint(
//       Offset(size.width, size.height),
//       radius: Radius.circular(radius),
//       clockwise: true,
//     );
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }



import 'package:flutter/material.dart';
import 'package:p2/AddItemPage%20.dart';
import 'package:p2/Chats_Page.dart';
import 'package:p2/PaymentPage.dart';
import 'Orders.dart';
import 'Categories_Page.dart';
import 'app_locale.dart';
import 'Support_and_Help.dart';
import 'logout_confirmation.dart';

import 'Personal Information.dart';
import 'Favourite.dart';
import 'Coupons.dart';
import 'About App.dart';
import 'Remove Account.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool muteNotifications = false;
  bool appAppearance = false;
  int selectedBottom = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppLocale.locale,
      builder: (context, locale, child) {
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
                  child: Center(
                    child: Text(
                      AppLocale.t('my_profile'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

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
                              builder: (context) => const PersonalInfoPage()),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PaymentPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.favorite, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('favourite')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FavouritePage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.confirmation_num,
                            color: Colors.black),
                      ),
                      title: Text(AppLocale.t('coupons')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CouponsPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.info, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('about_app')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutAppPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.headset_mic, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('support_help')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SupportPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.language, color: Colors.black),
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
                                    title: const Text("English"),
                                    onTap: () {
                                      AppLocale.setLocale(const Locale('en'));
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text("عربي"),
                                    onTap: () {
                                      AppLocale.setLocale(const Locale('ar'));
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

                    SwitchListTile(
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

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child:
                            const Icon(Icons.delete_forever, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('remove_account')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RemoveAccountPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.logout, color: Colors.black),
                      ),
                      title: Text(AppLocale.t('logout')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LogoutConfirmationPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          bottomNavigationBar: Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF1B2230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildBottomIcon(Icons.settings, 0),
                buildBottomIcon(Icons.inventory_2_outlined, 1),
                buildBottomIcon(Icons.add, 2),
                buildBottomIcon(Icons.chat_bubble_outline, 3),
                buildBottomIcon(Icons.home_outlined, 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomIcon(IconData icon, int index) {
    bool active = selectedBottom == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottom = index;
        });

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrdersPage()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatsPage()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CategoryPage()),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: active ? 8 : 0),
        padding: const EdgeInsets.all(12),
        decoration: active
            ? BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: active ? 32 : 26,
          color: active ? Colors.black : Colors.white70,
        ),
      ),
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
