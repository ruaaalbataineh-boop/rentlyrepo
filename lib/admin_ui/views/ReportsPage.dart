import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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
                        context.pop();
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Reports",
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
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  _buildReportCard("Total Users", "120"),
                  _buildReportCard("Total Trips", "35"),
                  _buildReportCard("Revenue", "\$12,500"),
                  _buildReportCard("Tickets Sold", "560"),
                  _buildReportCard("Pending Requests", "8"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
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
