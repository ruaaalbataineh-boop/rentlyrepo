import 'package:flutter/material.dart';
import 'package:p2/Chats_Page.dart';
import 'package:p2/QrPage.dart';
import 'PaymentPage.dart'; // اضفته هون
import 'app_locale.dart';
import 'Setting.dart';
import 'Categories_Page.dart';
import 'EquipmentItem.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  static const routeName = '/orders';

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int selectedTab = 0;
  int selectedBottom = 1;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
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

                  /// ----------------------------
                  ///   زر الدفع + عنوان Orders
                  /// ----------------------------
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),

                      Text(
                        AppLocale.t('orders'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.payment,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PaymentPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildTab(AppLocale.t('new_orders'), 0),
                  const SizedBox(width: 40),
                  buildTab(AppLocale.t('current_orders'), 1),
                  const SizedBox(width: 40),
                  buildTab(AppLocale.t('previous_orders'), 2),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(child: buildTabContent()),
            ],
          ),

          bottomNavigationBar: buildBottomNav(),
        );
      },
    );
  }

  Widget buildTab(String text, int index) {
    bool active = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? const Color(0xFF8A005D) : Colors.black,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(30),
          color: active ? Colors.white : Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: active ? const Color(0xFF8A005D) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildTabContent() {
    List<EquipmentItem> items;
    String emptyText;

    if (selectedTab == 0) {
      items = OrdersManager.newOrders;
      emptyText = AppLocale.t('no_new_orders');
    } else if (selectedTab == 1) {
      items = OrdersManager.currentOrders;
      emptyText = AppLocale.t('no_current_orders');
    } else {
      items = OrdersManager.previousOrders;
      emptyText = AppLocale.t('no_previous_orders');
    }

    if (items.isEmpty) {
      return Center(
        child: Text(emptyText,
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(item.icon, color: const Color(0xFF8A005D), size: 35),
            title: Text(item.title, style: const TextStyle(fontSize: 18)),
            subtitle: Text("\$${item.pricePerDay.toStringAsFixed(2)} / day"),
            trailing: IconButton(
              icon: const Icon(Icons.qr_code,
                  color: Color(0xFF1F0F46), size: 30),
              onPressed: () {
                String qrData =
                    "Item: ${item.title}\nPrice: \$${item.pricePerDay}\nCondition: ${item.condition.name}";
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrPage(qrData: qrData),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomNav() {
    return Container(
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
          buildBottomIcon(Icons.settings, 0, const SettingPage()),
          buildBottomIcon(Icons.inventory_2_outlined, 1, const OrdersPage()),
          buildBottomIcon(Icons.add, 2, null),
          buildBottomIcon(Icons.chat_bubble_outline, 3, const ChatsPage()),
          buildBottomIcon(Icons.home_outlined, 4, const CategoryPage()),
        ],
      ),
    );
  }

  Widget buildBottomIcon(IconData icon, int index, Widget? page) {
    bool active = selectedBottom == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedBottom = index);
        if (page != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
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
                  )
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

class OrdersManager {
  static final List<EquipmentItem> newOrders = [];
  static final List<EquipmentItem> currentOrders = [];
  static final List<EquipmentItem> previousOrders = [];

  static void addOrder(EquipmentItem item) {
    if (!newOrders.contains(item)) {
      newOrders.add(item);
    }
  }

  static void moveToCurrent(EquipmentItem item) {
    if (newOrders.remove(item)) currentOrders.add(item);
  }

  static void moveToPrevious(EquipmentItem item) {
    if (currentOrders.remove(item)) previousOrders.add(item);
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


// import 'package:flutter/material.dart';
// import 'package:p2/Chats_Page.dart';
// import 'package:p2/QrPage.dart';
// import 'app_locale.dart';
// import 'Setting.dart';
// import 'Categories_Page.dart';
// import 'EquipmentItem.dart';

// class OrdersPage extends StatefulWidget {
//   const OrdersPage({super.key});

//   static const routeName = '/orders';

//   @override
//   State<OrdersPage> createState() => _OrdersPageState();
// }

// class _OrdersPageState extends State<OrdersPage> {
//   int selectedTab = 0;
//   int selectedBottom = 1;

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<Locale>(
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
//                       AppLocale.t('orders'),
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

              
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   buildTab(AppLocale.t('new_orders'), 0),
//                   const SizedBox(width: 40),
//                   buildTab(AppLocale.t('current_orders'), 1),
//                   const SizedBox(width: 40),
//                   buildTab(AppLocale.t('previous_orders'), 2),
//                 ],
//               ),
//               const SizedBox(height: 25),

              
//               Expanded(child: buildTabContent()),
//             ],
//           ),


//           bottomNavigationBar: buildBottomNav(),
//         );
//       },
//     );
//   }

 
//   Widget buildTab(String text, int index) {
//     bool active = selectedTab == index;
//     return GestureDetector(
//       onTap: () => setState(() => selectedTab = index),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: active ? const Color(0xFF8A005D) : Colors.black,
//             width: 1.5,
//           ),
//           borderRadius: BorderRadius.circular(30),
//           color: active ? Colors.white : Colors.transparent,
//         ),
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 18,
//             color: active ? const Color(0xFF8A005D) : Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

 
//   Widget buildTabContent() {
//     List<EquipmentItem> items;
//     String emptyText;

//     if (selectedTab == 0) {
//       items = OrdersManager.newOrders;
//       emptyText = AppLocale.t('no_new_orders');
//     } else if (selectedTab == 1) {
//       items = OrdersManager.currentOrders;
//       emptyText = AppLocale.t('no_current_orders');
//     } else {
//       items = OrdersManager.previousOrders;
//       emptyText = AppLocale.t('no_previous_orders');
//     }

//     if (items.isEmpty) {
//       return Center(
//         child: Text(emptyText,
//             style: const TextStyle(fontSize: 16, color: Colors.grey)),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(20),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final item = items[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 15),
//           elevation: 3,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           child: ListTile(
//             leading: Icon(item.icon, color: const Color(0xFF8A005D), size: 35),
//             title: Text(item.title, style: const TextStyle(fontSize: 18)),
//             subtitle: Text("\$${item.pricePerDay.toStringAsFixed(2)} / day"),
//             trailing: IconButton(
//               icon: const Icon(Icons.qr_code, color: Color(0xFF1F0F46), size: 30),
//               onPressed: () {
//                 String qrData =
//                     "Item: ${item.title}\nPrice: \$${item.pricePerDay}\nCondition: ${item.condition.name}";
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => QrPage(qrData: qrData),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

  
//   Widget buildBottomNav() {
//     return Container(
//       height: 70,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1B2230),
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           buildBottomIcon(Icons.settings, 0, const SettingPage()),
//           buildBottomIcon(Icons.inventory_2_outlined, 1, const OrdersPage()),
//           buildBottomIcon(Icons.add, 2, null),
//           buildBottomIcon(Icons.chat_bubble_outline, 3, const ChatsPage()),
//           buildBottomIcon(Icons.home_outlined, 4, const CategoryPage()),
//         ],
//       ),
//     );
//   }

  
//   Widget buildBottomIcon(IconData icon, int index, Widget? page) {
//     bool active = selectedBottom == index;

//     return GestureDetector(
//       onTap: () {
//         setState(() => selectedBottom = index);
//         if (page != null) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => page),
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
//                   )
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


// class OrdersManager {
//   static final List<EquipmentItem> newOrders = [];
//   static final List<EquipmentItem> currentOrders = [];
//   static final List<EquipmentItem> previousOrders = [];

//   static void addOrder(EquipmentItem item) {
//     if (!newOrders.contains(item)) {
//       newOrders.add(item);
//     }
//   }

//   static void moveToCurrent(EquipmentItem item) {
//     if (newOrders.remove(item)) currentOrders.add(item);
//   }

//   static void moveToPrevious(EquipmentItem item) {
//     if (currentOrders.remove(item)) previousOrders.add(item);
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

