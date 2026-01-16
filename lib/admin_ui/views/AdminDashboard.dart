import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          Stack(
            children: [
              ClipPath(
                clipper: SideCurveClipper(),
                child: Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        context.go('/adminLogin');
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Admin Dashboard",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(context, "User Management", Icons.person, '/users'),
                  _buildDashboardCard(context, "Wallet", Icons.wallet, '/wallet'),
                  _buildDashboardCard(context, "Item Management", Icons.inventory, '/items'),
                  _buildDashboardCard(context, "Transactions", Icons.monetization_on, '/transactions'),
                  _buildDashboardCard(context, "Complaints", Icons.report_problem, '/complaints'),
                  _buildDashboardCard(context, "Reports", Icons.bar_chart, '/reports'),
                  _buildDashboardCard(context, "Notify Users", Icons.notifications, '/notifications'),
                  _buildDashboardCard(context, "Chats", Icons.chat, '/chats'),
                  _buildDashboardCard(context, "Logout", Icons.logout, '/adminLogin'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        context.go(route);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
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
