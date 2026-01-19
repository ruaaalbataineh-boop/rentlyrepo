
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2/services/auth_service.dart';
import 'package:p2/services/equipment_detail_service.dart';
import 'package:provider/provider.dart';
import 'ChatScreen.dart';
import 'AllReviewsPage.dart';
import 'UserProfilePage.dart';
import '../WalletRechargePage.dart';
import '../controllers/equipment_detail_controller.dart';
import '../controllers/favourite_controller.dart';
import '../models/Item.dart';
import 'package:p2/security/error_handler.dart';

import 'app_shell.dart';

class EquipmentDetailPage extends StatefulWidget {
  static const routeName = '/product-details';
  const EquipmentDetailPage({super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  int currentPage = 0;
  bool _loaded = false;
  Item? _item;
  List<Map<String, dynamic>> topReviews = [];

  late EquipmentDetailController _controller;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  get stack => null;

  @override
  void initState() {
    super.initState();

    _controller = EquipmentDetailController(
      EquipmentDetailService(
        FirebaseFirestore.instance,
        FirebaseFunctions.instance,
      ),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (!_loaded && args is Item) {
      _item = args;

      final auth = context.read<AuthService>();
      final uid = auth.currentUid;

      if (uid == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
        });
        return;
      }

      _controller.load(
        item: _item!,
        currentUserId: uid,
      );

      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null || _controller.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final item = _item!;
    final periods = item.rentalPeriods.keys
    .where((p) => p.toLowerCase() != 'hourly')
    .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTopHeader(context),
              buildImageSlider(item.images),
              buildHeader(item),
              buildOwnerSection(),
              buildDescription(item),
              buildRatingSection(item),

              if (_controller.isOwner) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "This is your item. You cannot rent your own item.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (_controller.isRentalBlockedUser) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "Your account is blocked from renting due to an unresolved rental.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                buildRentalChips(periods, item),
                buildRentalSelector(),
                buildAvailabilityHint(),
                buildEndDateDisplay(),
                buildTotalPrice(),
                buildInsuranceSection(),
                buildPickupSelector(),
                buildRentButton(item),
              ],

              buildReviewsSection(item),
              buildMapSection(item),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
             // _logic.cleanupResources();
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              "Item Details",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget buildImageSlider(List<String> images) {
    return Container(
      height: 260,
      margin: const EdgeInsets.all(12),
      child: PageView.builder(
        onPageChanged: (i) => setState(() => currentPage = i),
        itemCount: images.isEmpty ? 1 : images.length,
        itemBuilder: (_, i) {
          if (images.isEmpty) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 90),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(images[i], fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  Widget buildHeader(Item item) {
    final fav = context.watch<FavouriteController>();
    final auth = context.read<AuthService>();
    final uid = auth.currentUid!;

    fav.bindIfNeeded(uid);

    final isFav = fav.isFavourite(item.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: isFav ? Colors.red : Colors.grey,
              size: 30,
            ),
            onPressed: () async {
              await fav.toggle(item.id);
            },
          ),
          if (!_controller.isOwner)
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF8A005D), size: 28),
              onPressed: () {
                final auth = context.read<AuthService>();
                final myUid = auth.currentUid;

                if (myUid == null || myUid == item.ownerId) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      personUid: item.ownerId,
                      personName: _controller.ownerName,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildOwnerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF8A005D)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(
                    userId: _item!.ownerId,
                    userName: _controller.ownerName,
                    showReviewsFromRenters: true,
                  ),
                ),
              );
            },
            child: Text(
              "Owner Name: ${_controller.ownerName}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                color: Color(0xFF8A005D),
                fontSize: 16,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget buildDescription(Item item) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(item.description,
          style: const TextStyle(fontSize: 15, color: Colors.black87)),
    );
  }

  Widget buildRatingSection(Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("items")
            .doc(item.id)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Row(
              children: const [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 6),
                Text("0.0 (0)"),
              ],
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          final ratingSum = (data["ratingSum"] ?? 0).toDouble();
          final ratingCount = (data["ratingCount"] ?? 0).toInt();

          final avg = ratingCount == 0 ? 0.0 : ratingSum / ratingCount;

          return Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 22),
              const SizedBox(width: 4),
              Text(
                "${avg.toStringAsFixed(1)} ($ratingCount)",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildRentalChips(List<String> periods, Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        children: periods.map((p) {
          return ChoiceChip(
            label: Text("$p (${item.rentalPeriods[p]}JD)"),
            selected: _controller.selectedPeriod == p,
            onSelected: (_) {
              setState(() {
                _controller.selectPeriod(p);
                _controller.startDate = null;
                _controller.endDate = null;
                _controller.count = 1;
                _controller.pickupTime = null;
                _controller.insuranceAccepted = false;
                _controller.selectPeriod(p);
              });
            },
            selectedColor: const Color(0xFF8A005D),
            labelStyle: TextStyle(
              color: _controller.selectedPeriod == p ? Colors.white : Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildRentalSelector() {
    if (_controller.selectedPeriod == null) return const SizedBox.shrink();
    final p = _controller.selectedPeriod!.toLowerCase();

    return buildDaySelector();
  }

  Widget buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDatePicker("Start Date", _controller.startDate, (d) {
            setState(() {
              _controller.setStartDate(d);
              _controller.calculateEndDate();
            });
          }),
          const SizedBox(height: 22),
          Text(
            "Number of ${_controller.getUnitLabel()}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_controller.count > 1) {
                      setState(() {
                        _controller.decrementCount();
                        _controller.calculateEndDate();
                      });
                    }
                  },
                  child: const Icon(Icons.remove,
                      color: Color(0xFF8A005D), size: 26),
                ),
                Text(
                  "${_controller.count} ${_controller.getUnitLabel()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A005D),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.incrementCount();
                      _controller.calculateEndDate();
                    });
                  },
                  child: const Icon(Icons.add, color: Color(0xFF8A005D), size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInsuranceSection() {
    if (_controller.selectedPeriod == null ||
        _controller.startDate == null ||
        _controller.endDate == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    "Insurance Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      "Original Market Price:",
                      "${(_controller.insuranceInfo?['itemOriginalPrice'] ?? 0).toStringAsFixed(2)}JD",
                    ),
                    _buildDetailRow(
                      "Insurance Rate:",
                      "${((_controller.insuranceInfo?['ratePercentage'] ?? 0) * 100).toInt()}%",
                    ),
                    const Divider(),
                    _buildDetailRow(
                      "Total Insurance:",
                      "${_controller.insuranceAmount.toStringAsFixed(2)}JD",
                      isBold: true,
                      color: Colors.blue[900],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // CHECKBOX
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _controller.insuranceAccepted,
                    onChanged: (value) {
                      setState(() => _controller.setInsuranceAccepted(value ?? false));
                      },
                    activeColor: const Color(0xFF8A005D),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Accept Insurance Terms",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "By checking this box, I agree to:\n"
                              "• Accept the insurance coverage required\n"
                              "• Pay insurance amount of ${_controller.insuranceAmount.toStringAsFixed(2)}JD\n"
                              "• Report any damages immediately\n"
                              "• Insurance will be refunded if item returned safely",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAvailabilityHint() {

    if (_controller.unavailableRanges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text(
              "Fully available for selected dates",
              style: TextStyle(color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            " Unavailable Periods",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          ..._controller.unavailableRanges.map((r) => Text(
            "• ${DateFormat('MMM d, HH:mm').format(r.start)} → ${DateFormat('MMM d, HH:mm').format(r.end)}",
            style: const TextStyle(color: Colors.red, fontSize: 13),
          )),
          const SizedBox(height: 8),
          const Text(
            "Please select different date range to proceed.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildDatePicker(
      String title, DateTime? value, Function(DateTime) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final blocked = EquipmentDetailController.buildBlockedDays(_controller.unavailableRanges);

              final pick = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                selectableDayPredicate: (day) {
                  // gray/disabled days
                  return !blocked.any((d) => _isSameDay(d, day));
                },
              );
              if (pick != null) onSelect(pick);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              value == null
                  ? "Select Start Date"
                  : DateFormat("yyyy-MM-dd").format(value),
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTimePicker(
      String title, TimeOfDay? value, Function(TimeOfDay) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final pick =
                  await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (pick != null) onSelect(pick);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(value == null ? "Select Time" : value.format(context),
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEndDateDisplay() {
    if (_controller.endDate == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        "End: ${_controller.formatEndDate()}",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A005D),
        ),
      ),
    );
  }

  Widget buildTotalPrice() {
    if (_controller.selectedPeriod == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Rental Price:",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    "JD ${_controller.rentalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A005D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPickupSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              "Pickup Time",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final pick = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (pick != null) {
                  setState(() => _controller.setPickupTime(pick.format(context)));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A005D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _controller.pickupTime == null ? "Select Pickup Time" : _controller.pickupTime!,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRentButton(Item item) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                const Text(
                  "Final Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F0F46),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow("Rental Price:", _controller.rentalPrice),
                _buildSummaryRow("Insurance:", _controller.insuranceAmount),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Price:", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${_controller.totalPrice.toStringAsFixed(2)}JD",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A005D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Wallet Balance:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "${_controller.renterWallet.toStringAsFixed(2)}JD",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _controller.hasSufficientBalance ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (!_controller.hasSufficientBalance)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[800], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "You need ${(_controller.totalPrice - _controller.renterWallet).toStringAsFixed(2)}JD more",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.canRent() ? const Color(0xFF8A005D) : Colors.grey,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _controller.canRent() ? 3 : 0,
            ),
            onPressed: _controller.canRent() ? () async {
              await _processRentalRequest(item);
            } : null,
            child: Text(
              _controller.getRentButtonText(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          
          if (!_controller.hasSufficientBalance) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8A005D)),
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pushNamed(context, WalletRechargePage.routeName);
              },
              child: const Text(
                "TopUp Wallet",
                style: TextStyle(color: Color(0xFF8A005D)),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, {String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text("${amount.toStringAsFixed(2)}JD"),
              if (note != null)
                Text(
                  " $note",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processRentalRequest(Item item) async {
    try {
      if (!_validateRentalInputs()) return;

      final confirmed = await showConfirmationDialog(context, item);

      if (!confirmed) return;

      // Optional loading UX
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _controller.createRentalRequest();

      if (mounted) Navigator.pop(context); // close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Rental request submitted successfully!"),
          backgroundColor: Colors.green[700],
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AppShell(initialIndex: 1), // Orders tab
          ),
              (_) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading dialog if open

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${ErrorHandler.getSafeError(e)}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateRentalInputs() {
    // Security: Validate all inputs
    if (_controller.selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rental period"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_controller.startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select start date"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (!_controller.insuranceAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You should accept the insurance terms and conditions"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_controller.pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select pickup time"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_controller.checkDateConflict()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected dates are not available. Please choose different dates."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!_controller.hasSufficientBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient wallet balance. Please top up your wallet."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<bool> showConfirmationDialog(BuildContext context, Item item) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Are you sure you want to submit rental request?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () => _showPolicyDialog(context),
              child: const Text(
                "By confirming you agree to Rently's Terms & Privacy Policy",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Here goes our full terms and privacy policy text...\n\n"
                "Our data usage, storage, responsibility, etc.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget buildReviewsSection(Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (topReviews.isEmpty)
            const Text(
              "No reviews yet",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: topReviews.map((rev) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 6),
                          Text("${rev['rating']}"),
                          const Spacer(),
                          Text(
                            DateFormat("MMM d").format(rev['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rev['comment'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "By anonymous user",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllReviewsPage(itemId: item.id),
                  ),
                );
              },
              child: const Text("Show All Reviews →"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMapSection(Item item) {
    if (item.latitude == null || item.longitude == null) {
      return Container(
        height: 150,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            " Location not provided",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

  return Container(
  height: 200,
  margin: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
  ),
  clipBehavior: Clip.hardEdge,
  child: GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(item.latitude!, item.longitude!),
      zoom: 14,
    ),
    markers: {
      Marker(
        markerId: const MarkerId("item_location"),
        position: LatLng(item.latitude!, item.longitude!),
      ),
    },
    myLocationEnabled: false,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
  ),
);

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
