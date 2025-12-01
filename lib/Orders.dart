
import 'package:flutter/material.dart';
import 'package:p2/AddItemPage%20.dart';
import 'package:p2/Chats_Page.dart';
import 'package:p2/QrPage.dart';
import 'PaymentPage.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

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
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.06,
                    bottom: screenHeight * 0.07,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: screenWidth * 0.1),
                      Text(
                        AppLocale.t('orders'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.payment,
                            color: Colors.white, 
                            size: isSmallScreen ? 24 : 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildTab(AppLocale.t('new_orders'), 0, screenWidth),
                  SizedBox(width: isSmallScreen ? 20 : 40),
                  buildTab(AppLocale.t('current_orders'), 1, screenWidth),
                  SizedBox(width: isSmallScreen ? 20 : 40),
                  buildTab(AppLocale.t('previous_orders'), 2, screenWidth),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              Expanded(child: buildTabContent(screenWidth)),
            ],
          ),
          bottomNavigationBar: buildBottomNav(screenWidth),
        );
      },
    );
  }

  Widget buildTab(String text, int index, double screenWidth) {
  bool active = selectedTab == index;
  final isSmallScreen = screenWidth < 380;

  return GestureDetector(
    onTap: () => setState(() => selectedTab = index),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 18,
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? const Color(0xFF8A005D) : Colors.black,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(25),
        color: active ? Colors.white : Colors.transparent,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 14,  
            color: active ? const Color(0xFF8A005D) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}


  Widget buildTabContent(double screenWidth) {
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
        child: Text(
          emptyText,
          style: TextStyle(
            fontSize: screenWidth < 360 ? 14 : 16,
            color: Colors.grey
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.05),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.only(bottom: screenWidth * 0.04),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(
              item.icon, 
              color: const Color(0xFF8A005D), 
              size: screenWidth < 360 ? 28 : 35
            ),
            title: Text(
              item.title, 
              style: TextStyle(
                fontSize: screenWidth < 360 ? 16 : 18
              )
            ),
            subtitle: Text(
              "JOD ${item.getPriceForRentalType(item.rentalType).toStringAsFixed(2)} / ${_getRentalTypeText(item.rentalType)}",
              style: TextStyle(
                fontSize: screenWidth < 360 ? 12 : 14
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.qr_code,
                color: const Color(0xFF1F0F46), 
                size: screenWidth < 360 ? 24 : 30
              ),
              onPressed: () {
                String qrData =
                    "Item: ${item.title}\nPrice: JOD ${item.getPriceForRentalType(item.rentalType).toStringAsFixed(2)}\nRental Type: ${_getRentalTypeText(item.rentalType)}";
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

  String _getRentalTypeText(RentalType type) {
    switch (type) {
      case RentalType.hourly:
        return 'hour';
        case RentalType.daily:
        return 'day';
      case RentalType.weekly:
        return 'week';
      case RentalType.monthly:
        return 'month';
      case RentalType.yearly:
        return 'year';
    }
  }

  Widget buildBottomNav(double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      height: isSmallScreen ? 60 : 70,
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
          buildBottomIcon(Icons.settings, 0, const SettingPage(), screenWidth),
          buildBottomIcon(Icons.inventory_2_outlined, 1, const OrdersPage(), screenWidth),
          buildBottomIcon(Icons.add, 2, null, screenWidth),
          buildBottomIcon(Icons.chat_bubble_outline, 3, const ChatsPage(), screenWidth),
          buildBottomIcon(Icons.home_outlined, 4, const CategoryPage(), screenWidth),
        ],
      ),
    );
  }

  Widget buildBottomIcon(IconData icon, int index, Widget? page, double screenWidth) {
    bool active = selectedBottom == index;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: () {
        setState(() => selectedBottom = index);

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage(item: null)),
          );
          return;
        }

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
        margin: EdgeInsets.only(bottom: active ? (isSmallScreen ? 6 : 8) : 0),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
          size: active ? (isSmallScreen ? 28 : 32) : (isSmallScreen ? 22 : 26),
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

