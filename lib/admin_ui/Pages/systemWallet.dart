import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SystemWalletPage extends StatefulWidget {
  const SystemWalletPage({super.key});

  @override
  State<SystemWalletPage> createState() => _SystemWalletPageState();
}

class _SystemWalletPageState extends State<SystemWalletPage> {
  String? adminWalletId;

  @override
  void initState() {
    super.initState();
    _loadAdminWallet();
  }

  Future<void> _loadAdminWallet() async {
    final snap = await FirebaseFirestore.instance
        .collection("wallets")
        .where("type", isEqualTo: "ADMIN")
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      setState(() => adminWalletId = snap.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          _buildHeader(),

          if (adminWalletId == null)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 22),
                    _buildTransactionsList(),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: SideCurveClipper(),
          child: Container(
            height: 150,
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
          top: 55,
          left: 16,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(width: 10),
              const Text(
                "System Wallet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // BALANCE CARD
  Widget _buildBalanceCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("wallets")
          .where("type", isEqualTo: "ADMIN")
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        double balance = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          balance = (snapshot.data!.docs.first["balance"] ?? 0).toDouble();
        }

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "ADMIN BALANCE",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "${balance.toStringAsFixed(2)}JD",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Total commissions currently held by platform",
                style: TextStyle(color: Colors.white70),
              )
            ],
          ),
        );
      },
    );
  }

  // TRANSACTION LIST
  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history, color: Color(0xFF1F0F46)),
            SizedBox(width: 8),
            Text(
              "System Wallet Transactions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F0F46)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("walletTransactions")
              .where("toWalletId", isEqualTo: adminWalletId)
              .orderBy("createdAt", descending: true)
              .limit(40)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      "No transactions yet",
                      style: TextStyle(color: Colors.black54),
                    )
                  ],
                ),
              );
            }

            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final amount = (data["amount"] ?? 0).toDouble();
                final purpose = data["purpose"] ?? "Unknown";
                final ts = (data["createdAt"] as Timestamp).toDate();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              purpose,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F0F46)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${ts.year}-${ts.month}-${ts.day}  ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                            )
                          ]),
                      Text(
                        "+${amount.toStringAsFixed(2)}JD",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }
}

// SAME CLIPPER
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
