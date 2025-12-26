import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/user_manager.dart';
import 'Item.dart';
import 'FavouriteManager.dart';
import 'ChatScreen.dart';
import 'AllReviewsPage.dart';

class EquipmentDetailPage extends StatefulWidget {
  static const routeName = '/product-details';
  const EquipmentDetailPage({super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  int currentPage = 0;
  String ownerName = "Loading...";
  String? selectedPeriod;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  int count = 1;
  String? pickupTime;
  
  double insuranceAmount = 0.0;
  double rentalPrice = 0.0;
  double totalRequired = 0.0;
  double totalPrice = 0.0; 
  double renterWallet = 0.0;
  bool hasSufficientBalance = false;
  bool insuranceAccepted = false;
  
  Map<String, dynamic>? itemInsuranceInfo;
  
  List<Map<String, dynamic>> topReviews = [];
  List<DateTimeRange> unavailableRanges = [];
  bool loadingAvailability = false;
  Item? _item;
  bool _loaded = false;

  double dailyPenaltyRate = 0.15;
  double hourlyPenaltyRate = 0.05;
  double maxPenaltyDays = 5;
  double maxPenaltyHours = 24;
  String penaltyMessage = "";
  bool showPenaltyInfo = false;

  bool get isOwner => _item != null && _item!.ownerId == UserManager.uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Item) {
        _item = args;
        loadOwnerName(_item!.ownerId);
        loadTopReviews(_item!.id);
        loadUnavailableRanges(_item!.id);
        loadItemInsuranceInfo(_item!.id);
        loadRenterWalletBalance();
      }
      _loaded = true;
    }
  }

  Future<void> loadOwnerName(String uid) async {
    final snap = await FirebaseDatabase.instance.ref("users/$uid/name").get();
    if (!mounted) return;
    setState(() {
      ownerName = snap.exists ? snap.value.toString() : "Owner";
    });
  }

  Future<void> loadItemInsuranceInfo(String itemId) async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref("items/$itemId/insurance")
          .get();
      
      if (snap.exists) {
        final data = snap.value as Map<dynamic, dynamic>;
        setState(() {
          itemInsuranceInfo = {
            'itemOriginalPrice': (data['itemOriginalPrice'] ?? 0.0).toDouble(),
            'ratePercentage': (data['ratePercentage'] ?? 0.15).toDouble(),
          };
          
          final itemPrice = itemInsuranceInfo!['itemOriginalPrice'];
          final rate = itemInsuranceInfo!['ratePercentage'];
          insuranceAmount = itemPrice * rate;
          
          insuranceAmount = (insuranceAmount / 5).ceil() * 5.0;
          if (insuranceAmount < 5) insuranceAmount = 5.0;
          
          calculateInsurance();
        });
      } else {
        setState(() {
          itemInsuranceInfo = {
            'itemOriginalPrice': 1000.0,
            'ratePercentage': 0.15,
          };
          insuranceAmount = 150.0;
          calculateInsurance();
        });
      }
    } catch (e) {
      debugPrint("Error loading insurance info: $e");
      setState(() {
        itemInsuranceInfo = {
          'itemOriginalPrice': 1000.0,
          'ratePercentage': 0.15,
        };
        insuranceAmount = 150.0;
        calculateInsurance();
      });
    }
  }

  Future<void> loadRenterWalletBalance() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref("users/${UserManager.uid}/wallet/balance")
          .get();
      
      if (snap.exists) {
        final balance = snap.value;
        if (balance != null) {
          setState(() {
            renterWallet = double.tryParse(balance.toString()) ?? 0.0;
            checkWalletBalance();
          });
        }
      } else {
        await FirebaseDatabase.instance
            .ref("users/${UserManager.uid}/wallet")
            .set({
              "balance": 2000.0,
              "currency": "JD",
              "lastUpdated": DateTime.now().toIso8601String(),
            });
        
        if (mounted) {
          setState(() {
            renterWallet = 2000.0;
            checkWalletBalance();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading wallet balance: $e");
      setState(() {
        renterWallet = 0.0;
        checkWalletBalance();
      });
    }
  }

  Future<void> loadTopReviews(String itemId) async {
    final snap = await FirebaseDatabase.instance
        .ref("reviews/$itemId")
        .limitToFirst(3)
        .get();

    if (!mounted) return;

    if (snap.exists) {
      setState(() {
        topReviews = snap.children.map((c) {
          return {
            "rating": c.child("rating").value ?? 0,
            "review": c.child("review").value ?? "",
          };
        }).toList();
      });
    } else {
      setState(() => topReviews = []);
    }
  }

  Future<void> loadUnavailableRanges(String itemId) async {
    setState(() => loadingAvailability = true);

    final rentals = await FirestoreService.getAcceptedRequestsForItem(itemId);

    unavailableRanges = rentals.map((r) {
      return DateTimeRange(
        start: DateTime.parse(r["startDate"]),
        end: DateTime.parse(r["endDate"]),
      );
    }).toList();

    if (!mounted) return;
    setState(() => loadingAvailability = false);
  }

  void calculateEndDate() {
    if (selectedPeriod == null) {
      endDate = null;
      return;
    }

    final p = selectedPeriod!.toLowerCase();

    if (p == "hourly") {
      if (startDate == null || startTime == null) {
        endDate = null;
        return;
      }

      final startDateTime = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      endDate = startDateTime.add(Duration(hours: count));
      calculateInsurance();
      return;
    }

    if (startDate == null) {
      endDate = null;
      return;
    }

    int days = 0;
    if (p == "daily") days = count;
    if (p == "weekly") days = count * 7;
    if (p == "monthly") days = count * 30;
    if (p == "yearly") days = count * 365;

    endDate = startDate!.add(Duration(days: days));
    calculateInsurance();
  }

  double computeTotalPrice(Item item) {
    if (selectedPeriod == null) return 0;
    final base = double.tryParse("${item.rentalPeriods[selectedPeriod]}") ?? 0;
    if (selectedPeriod!.toLowerCase() == "hourly") {
      return base * count;
    }
    return base * count;
  }

  void calculatePenalties() {
    if (_item == null || selectedPeriod == null || itemInsuranceInfo == null) {
      setState(() {
        penaltyMessage = "";
        showPenaltyInfo = false;
      });
      return;
    }

    final isHourly = selectedPeriod!.toLowerCase() == "hourly";
    final itemOriginalPrice = itemInsuranceInfo!['itemOriginalPrice'];
    
    String message = "";
    
    if (isHourly) {
      final penaltyPerHour = itemOriginalPrice * hourlyPenaltyRate;
      message = "⏰ Hourly rental: If late more than 24 hours:\n"
          "• 5% penalty per late hour (JD ${penaltyPerHour.toStringAsFixed(2)}/hour)\n"
          "• Deducted from insurance\n";
         
    } else {
      final penaltyPerDay = itemOriginalPrice * dailyPenaltyRate;
      message = "📅 Daily/Weekly/Monthly: If late more than 5 days:\n"
          "• 15% penalty per late day (JD ${penaltyPerDay.toStringAsFixed(2)}/day)\n"
          "• Deducted from insurance\n";
        
    }
    
    setState(() {
      penaltyMessage = message;
      showPenaltyInfo = true;
    });
  }

  void calculateInsurance() {
    if (_item == null || selectedPeriod == null || itemInsuranceInfo == null) return;
    
    rentalPrice = computeTotalPrice(_item!);
    totalPrice = rentalPrice + insuranceAmount; 
    totalRequired = totalPrice; 
    
    calculatePenalties();
    
    checkWalletBalance();
    
    setState(() {});
  }

  void checkWalletBalance() {
    if (renterWallet >= totalRequired) {
      setState(() {
        hasSufficientBalance = true;
      });
    } else {
      setState(() {
        hasSufficientBalance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final item = _item!;
    final periods = item.rentalPeriods.keys.toList();

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

              if (!isOwner) ...[
                buildRentalChips(periods, item),
                buildRentalSelector(item),
                buildAvailabilityHint(),
                buildEndDateDisplay(),
                buildTotalPrice(item),
                buildInsuranceAndBalanceSection(),
                buildPenaltyInfoSection(),
                buildInsuranceTermsCheckbox(),
                buildPickupSelector(),
                buildRentButton(item),
              ] else ...[
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
            onPressed: () => Navigator.pop(context),
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
    final isFav = FavouriteManager.isFavourite(item.id);

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
            onPressed: () {
              setState(() {
                isFav
                    ? FavouriteManager.remove(item.id)
                    : FavouriteManager.add(item.id);
              });
            },
          ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF8A005D), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      personUid: item.ownerId,
                      personName: ownerName,
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
          Text("Owner: $ownerName"),
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
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber[700], size: 22),
          const SizedBox(width: 4),
          Text("${item.averageRating.toStringAsFixed(1)} (${item.ratingCount})"),
        ],
      )
    );
  }

  Widget buildRentalChips(List<String> periods, Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        children: periods.map((p) {
          return ChoiceChip(
            label: Text("$p (JD ${item.rentalPeriods[p]})"),
            selected: selectedPeriod == p,
            onSelected: (_) {
              setState(() {
                selectedPeriod = p;
                startDate = null;
                endDate = null;
                startTime = null;
                count = 1;
                pickupTime = null;
                insuranceAccepted = false;
                calculateInsurance();
              });
            },
            selectedColor: const Color(0xFF8A005D),
            labelStyle: TextStyle(
              color: selectedPeriod == p ? Colors.white : Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildRentalSelector(Item item) {
    if (selectedPeriod == null) return const SizedBox.shrink();
    final p = selectedPeriod!.toLowerCase();

    if (p == "hourly") return buildHourlySelector();
    return buildDaySelector();
  }

  Widget buildHourlySelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDatePicker("Start Date", startDate, (d) {
            setState(() {
              startDate = d;
              calculateEndDate();
            });
          }),
          const SizedBox(height: 16),
          buildTimePicker("Start Time", startTime, (t) {
            setState(() {
              startTime = t;
              calculateEndDate();
            });
          }),
          const SizedBox(height: 22),
          const Text(
            "Number of Hours",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    if (count > 1) {
                      setState(() {
                        count--;
                        calculateEndDate();
                      });
                    }
                  },
                  child: const Icon(Icons.remove,
                      color: Color(0xFF8A005D), size: 26),
                ),
                Text(
                  "$count Hours",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A005D),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      count++;
                      calculateEndDate();
                    });
                  },
                  child: const Icon(Icons.add,
                      color: Color(0xFF8A005D), size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDaySelector() {
    String unitLabel = "Days";
    final p = selectedPeriod?.toLowerCase();
    if (p == "weekly") unitLabel = "Weeks";
    if (p == "monthly") unitLabel = "Months";
    if (p == "yearly") unitLabel = "Years";

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDatePicker("Start Date", startDate, (d) {
            setState(() {
              startDate = d;
              calculateEndDate();
            });
          }),
          const SizedBox(height: 22),
          Text(
            "Number of $unitLabel",
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
                    if (count > 1) {
                      setState(() {
                        count--;
                        calculateEndDate();
                      });
                    }
                  },
                  child: const Icon(Icons.remove,
                      color: Color(0xFF8A005D), size: 26),
                ),
                Text(
                  "$count $unitLabel",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A005D),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      count++;
                      calculateEndDate();
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

  Widget buildInsuranceAndBalanceSection() {
    if (selectedPeriod == null || startDate == null || endDate == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F0F46),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Insurance & Wallet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
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
                      Icon(
                        Icons.shield,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Insurance Required",
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
                          "Item Original Price:",
                          "JD ${(itemInsuranceInfo?['itemOriginalPrice'] ?? 0).toStringAsFixed(2)}",
                        ),
                        _buildDetailRow(
                          "Insurance Rate:",
                          "${((itemInsuranceInfo?['ratePercentage'] ?? 0) * 100).toInt()}%",
                        ),
                        const Divider(),
                        _buildDetailRow(
                          "Insurance Amount:",
                          "JD ${insuranceAmount.toStringAsFixed(2)}",
                          isBold: true,
                          color: Colors.blue[900],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: hasSufficientBalance ? Colors.green[50] : Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasSufficientBalance ? Icons.account_balance_wallet : Icons.warning,
                        color: hasSufficientBalance ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        hasSufficientBalance ? "Sufficient Balance" : "Check Your Balance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasSufficientBalance ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        _buildBalanceRow(
                          "Rental Price:",
                          rentalPrice,
                        ),
                        _buildBalanceRow(
                          "Insurance Amount:",
                          insuranceAmount,
                        ),
                        const Divider(),
                        _buildBalanceRow(
                          "Total Price:", 
                          totalPrice, 
                          isTotal: true,
                          color: hasSufficientBalance ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Wallet Balance:",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "JD ${renterWallet.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: renterWallet > 0 ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!hasSufficientBalance) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.orange[800], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Insufficient Balance",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "You need JD ${(totalRequired - renterWallet).toStringAsFixed(2)} more",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPenaltyInfoSection() {
    if (!showPenaltyInfo || penaltyMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300, width: 1),
        ),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, 
                  color: Colors.orange[800], size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  penaltyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
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

  Widget _buildBalanceRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              color: isTotal ? Colors.black : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "JD ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? Color(0xFF8A005D) : Colors.black),
            ),
          ),
        ],
      )
    );
  }

  Widget buildAvailabilityHint() {
    if (loadingAvailability) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (unavailableRanges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text(
              "Fully available for selected dates",
              style: TextStyle(color: Colors.green),
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
            "⚠️ Unavailable Periods",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          ...unavailableRanges.map((r) => Text(
            "• ${DateFormat('MMM d, HH:mm').format(r.start)} → ${DateFormat('MMM d, HH:mm').format(r.end)}",
            style: const TextStyle(color: Colors.red, fontSize: 13),
          )),
          const SizedBox(height: 8),
          const Text(
            "Please select different dates to proceed.",
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
              final pick = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
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
              style: const TextStyle(fontSize: 15),
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
            child: Text(value == null ? "Select Time" : value.format(context)),
          ),
        ),
      ],
    );
  }

  Widget buildEndDateDisplay() {
    if (endDate == null) return const SizedBox.shrink();

    final isHourly = selectedPeriod?.toLowerCase() == "hourly";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        isHourly
            ? "End Date & Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endDate!)}"
            : "End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A005D),
        ),
      ),
    );
  }

  Widget buildTotalPrice(Item item) {
    if (selectedPeriod == null) return const SizedBox.shrink();

    final rentalPrice = computeTotalPrice(item);
    
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
                    "JD ${rentalPrice.toStringAsFixed(2)}",
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

  Widget buildInsuranceTermsCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: insuranceAccepted,
                onChanged: (value) {
                  setState(() {
                    insuranceAccepted = value ?? false;
                  });
                },
                activeColor: const Color(0xFF8A005D),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Accept Owner's Insurance Terms",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "By checking this box, I agree to:\n"
                      "• Accept the insurance coverage required by owner\n"
                      "• Pay insurance amount of JD ${insuranceAmount.toStringAsFixed(2)}\n"
                      "• Report any damages immediately\n"
                      "• Understand insurance will be refunded if item returned safely",
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
                if (pick != null) setState(() => pickupTime = pick.format(context));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A005D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                pickupTime == null ? "Select Pickup Time" : pickupTime!,
                style: const TextStyle(fontSize: 15),
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
                
                _buildSummaryRow("Rental Price:", rentalPrice),
                _buildSummaryRow("Insurance:", insuranceAmount),
                
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
                      "JD ${totalPrice.toStringAsFixed(2)}", 
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
                      "JD ${renterWallet.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasSufficientBalance ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                
                if (!hasSufficientBalance)
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
                              "You need JD ${(totalPrice - renterWallet).toStringAsFixed(2)} more",
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
              backgroundColor: _canRent() ? const Color(0xFF8A005D) : Colors.grey,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _canRent() ? 3 : 0,
            ),
            onPressed: _canRent() ? () async {
              if (selectedPeriod == null ||
                  startDate == null ||
                  endDate == null ||
                  pickupTime == null ||
                  (selectedPeriod!.toLowerCase() == "hourly" && startTime == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please complete all required fields"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              if (!insuranceAccepted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please accept the insurance terms and conditions"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (startDate != null && endDate != null) {
                final hasConflict = checkDateConflict(
                  startDate!,
                  endDate!,
                  unavailableRanges,
                );
                
                if (hasConflict) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Selected dates are not available. Please choose different dates."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
              
              if (!hasSufficientBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Insufficient wallet balance. Please top up your wallet."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              calculateEndDate();
              
              final isHourly = selectedPeriod!.toLowerCase() == "hourly";
              
              final data = {
                "itemId": item.id,
                "itemTitle": item.name,
                "itemOwnerUid": item.ownerId,
                "customerUid": UserManager.uid,
                "customerName": UserManager.name,
                "status": "pending",
                "rentalType": selectedPeriod,
                "rentalQuantity": count,
                "startDate": startDate!.toIso8601String(),
                "endDate": endDate!.toIso8601String(),
                "startTime": isHourly ? startTime!.format(context) : null,
                "endTime": isHourly
                    ? TimeOfDay.fromDateTime(endDate!)
                        .format(context)
                    : null,
                "pickupTime": pickupTime,
                "rentalPrice": rentalPrice,
                "insuranceInfo": itemInsuranceInfo,
                "insuranceAmount": insuranceAmount,
                "totalPrice": totalPrice, 
                "totalRequired": totalRequired,
                "createdAt": DateTime.now().toIso8601String(),
                "insuranceAccepted": insuranceAccepted,
                "renterWalletBefore": renterWallet,
                "penaltyInfo": {
                  "dailyPenaltyRate": dailyPenaltyRate,
                  "hourlyPenaltyRate": hourlyPenaltyRate,
                  "maxPenaltyDays": maxPenaltyDays,
                  "maxPenaltyHours": maxPenaltyHours,
                  "penaltyMessage": penaltyMessage,
                },
              };
              
              final confirmed = await showConfirmationDialog(context, data, item);
              if (!confirmed) return;
              
              try {
                await FirestoreService.createRentalRequest(data);
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("✅ Rental request submitted successfully!"),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                await Future.delayed(const Duration(milliseconds: 1500));
                
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    "/orders", 
                    (route) => false
                  );
                }
                
              } on FirebaseFunctionsException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? "Failed to submit rental request"),
                    backgroundColor: Colors.red,
                  ),
                );
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Unexpected error. Please try again."),
                    backgroundColor: Colors.red,
                  ),
                );
                debugPrint("Error creating rental request: $e");
              }
            } : null,
            child: Text(
              _getRentButtonText(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          if (!hasSufficientBalance) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8A005D)),
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/wallet');
              },
              child: const Text(
                "Go to Wallet",
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
              Text("JD ${amount.toStringAsFixed(2)}"),
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

  bool _canRent() {
    return selectedPeriod != null &&
           startDate != null &&
           endDate != null &&
           pickupTime != null &&
           insuranceAccepted &&
           hasSufficientBalance;
  }

  String _getRentButtonText() {
    if (!hasSufficientBalance) return "Insufficient Wallet Balance";
    if (!insuranceAccepted) return "Accept Insurance Terms First";
    if (pickupTime == null) return "Select Pickup Time";
    if (startDate == null || endDate == null) return "Select Dates First";
    if (selectedPeriod == null) return "Select Rental Period";
    return "Confirm & Rent Now";
  }
  
  Future<bool> showConfirmationDialog(BuildContext context, Map<String, dynamic> data, Item item) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Rental Request"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please review your order details:"),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text("Owner: $ownerName"),
                    Text("Period: ${selectedPeriod!.toUpperCase()}"),
                    Text("Duration: $count ${selectedPeriod!.toLowerCase() == 'hourly' ? 'hours' : selectedPeriod!.toLowerCase()}"),
                    Text("Dates: ${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}"),
                    if (pickupTime != null) Text("Pickup: $pickupTime"),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Insurance Details:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text("Item Price: JD ${itemInsuranceInfo!['itemOriginalPrice']!.toStringAsFixed(2)}"),
                    Text("Insurance Rate: ${(itemInsuranceInfo!['ratePercentage']! * 100).toInt()}%"),
                    Text("Insurance: JD ${insuranceAmount.toStringAsFixed(2)}"),
                    const Text("Insurance will be refunded when item returned safely"),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[800], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Late Return Penalty:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      penaltyMessage,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price Summary:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildDialogRow("Rental Payment to Owner:", rentalPrice),
                    _buildDialogRow("Insurance Payment to System:", insuranceAmount),
                    const Divider(),
                    _buildDialogRow("Total Price:", totalPrice, isBold: true),
                    const SizedBox(height: 4),
                    Text(
                      "Current Wallet Balance: JD ${renterWallet.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                "By confirming, you agree to:\n"
                "• Rental terms and conditions\n"
                "• Insurance coverage selected by owner\n"
                "• Late return penalty policy\n"
                "• Report any damages immediately\n"
                "• Return and refund policy",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm & Proceed"),
          ),
        ],
      ),
    ) ?? false;
  }
  
  Widget _buildDialogRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          Text(
            "JD ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: isBold ? const Color(0xFF8A005D) : Colors.black,
            ),
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
                  constraints: const BoxConstraints(maxWidth: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rev['review'],
                        style: const TextStyle(fontSize: 14),
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
            "📍 Location not provided",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(20),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(item.latitude!, item.longitude!),
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("itemLoc"),
            position: LatLng(item.latitude!, item.longitude!),
          )
        },
      ),
    );
  }
}

bool checkDateConflict(
  DateTime selectedStart,
  DateTime selectedEnd,
  List<DateTimeRange> unavailableRanges,
) {
  for (final range in unavailableRanges) {
    if ((selectedStart.isBefore(range.end) || selectedStart.isAtSameMomentAs(range.end)) &&
        (selectedEnd.isAfter(range.start) || selectedEnd.isAtSameMomentAs(range.start))) {
      return true;
    }
  }
  return false;
}

















// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:p2/services/firestore_service.dart';
// import 'package:p2/user_manager.dart';
// import 'Item.dart';
// import 'FavouriteManager.dart';
// import 'ChatScreen.dart';
// import 'AllReviewsPage.dart';

// class EquipmentDetailPage extends StatefulWidget {
//   static const routeName = '/product-details';
//   const EquipmentDetailPage({super.key});

//   @override
//   State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
// }

// class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
//   int currentPage = 0;

//   String ownerName = "Loading...";

//   String? selectedPeriod;
//   DateTime? startDate;
//   DateTime? endDate;
//   TimeOfDay? startTime;
//   int count = 1;
//   String? pickupTime;

//   List<Map<String, dynamic>> topReviews = [];
//   List<DateTimeRange> unavailableRanges = [];
//   bool loadingAvailability = false;

//   Item? _item;
//   bool _loaded = false;

//   bool get isOwner => _item != null && _item!.ownerId == UserManager.uid;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (!_loaded) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args is Item) {
//         _item = args;
//         loadOwnerName(_item!.ownerId);
//         loadTopReviews(_item!.id);
//         loadUnavailableRanges(_item!.id);
//       }
//       _loaded = true;
//     }
//   }

//   Future<void> loadOwnerName(String uid) async {
//     final snap = await FirebaseDatabase.instance.ref("users/$uid/name").get();
//     if (!mounted) return;
//     setState(() {
//       ownerName = snap.exists ? snap.value.toString() : "Owner";
//     });
//   }

//   Future<void> loadTopReviews(String itemId) async {
//     final snap = await FirebaseDatabase.instance
//         .ref("reviews/$itemId")
//         .limitToFirst(3)
//         .get();

//     if (!mounted) return;

//     if (snap.exists) {
//       setState(() {
//         topReviews = snap.children.map((c) {
//           return {
//             "rating": c.child("rating").value ?? 0,
//             "review": c.child("review").value ?? "",
//           };
//         }).toList();
//       });
//     } else {
//       setState(() => topReviews = []);
//     }
//   }

//   Future<void> loadUnavailableRanges(String itemId) async {
//     setState(() => loadingAvailability = true);

//     final rentals =
//     await FirestoreService.getAcceptedRequestsForItem(itemId);

//     unavailableRanges = rentals.map((r) {
//       return DateTimeRange(
//         start: DateTime.parse(r["startDate"]),
//         end: DateTime.parse(r["endDate"]),
//       );
//     }).toList();

//     if (!mounted) return;
//     setState(() => loadingAvailability = false);
//   }

//   void calculateEndDate() {
//     if (selectedPeriod == null) {
//       endDate = null;
//       return;
//     }

//     final p = selectedPeriod!.toLowerCase();

//     if (p == "hourly") {
//       if (startDate == null || startTime == null) {
//         endDate = null;
//         return;
//       }

//       final startDateTime = DateTime(
//         startDate!.year,
//         startDate!.month,
//         startDate!.day,
//         startTime!.hour,
//         startTime!.minute,
//       );

//       // Add hours based on quantity
//       endDate = startDateTime.add(Duration(hours: count));
//       return;
//     }

//     // non-hourly
//     if (startDate == null) {
//       endDate = null;
//       return;
//     }

//     int days = 0;
//     if (p == "daily") days = count;
//     if (p == "weekly") days = count * 7;
//     if (p == "monthly") days = count * 30;
//     if (p == "yearly") days = count * 365;

//     endDate = startDate!.add(Duration(days: days));
//   }

//   double computeTotalPrice(Item item) {
//     if (selectedPeriod == null) return 0;

//     final base = double.tryParse("${item.rentalPeriods[selectedPeriod]}") ?? 0;

//     if (selectedPeriod!.toLowerCase() == "hourly") {
//       return base * count;
//     }

//     return base * count;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_item == null) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );
//     }

//     final item = _item!;
//     final periods = item.rentalPeriods.keys.toList();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               buildTopHeader(context),
//               buildImageSlider(item.images),
//               buildHeader(item),
//               buildOwnerSection(),
//               buildDescription(item),
//               buildRatingSection(item),

//               if (!isOwner) ...[
//                 buildRentalChips(periods, item),
//                 buildRentalSelector(item),
//                 buildAvailabilityHint(),
//                 buildEndDateDisplay(),
//                 buildTotalPrice(item),
//                 buildPickupSelector(),
//                 buildRentButton(item),
//               ] else ...[
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: const Text(
//                       "This is your item. You cannot rent your own item.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.black54,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],

//               buildReviewsSection(item),
//               buildMapSection(item),
//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // TOP HEADER
//   Widget buildTopHeader(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Expanded(
//             child: Text(
//               "Item Details",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           const SizedBox(width: 40),
//         ],
//       ),
//     );
//   }

//   // IMAGE SLIDER
//   Widget buildImageSlider(List<String> images) {
//     return Container(
//       height: 260,
//       margin: const EdgeInsets.all(12),
//       child: PageView.builder(
//         onPageChanged: (i) => setState(() => currentPage = i),
//         itemCount: images.isEmpty ? 1 : images.length,
//         itemBuilder: (_, i) {
//           if (images.isEmpty) {
//             return Container(
//               color: Colors.grey[200],
//               child: const Icon(Icons.image_not_supported, size: 90),
//             );
//           }
//           return ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: Image.network(images[i], fit: BoxFit.cover),
//           );
//         },
//       ),
//     );
//   }

//   // HEADER
//   Widget buildHeader(Item item) {
//     final isFav = FavouriteManager.isFavourite(item.id);

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               item.name,
//               style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//             ),
//           ),

//           IconButton(
//             icon: Icon(
//               Icons.favorite,
//               color: isFav ? Colors.red : Colors.grey,
//               size: 30,
//             ),
//             onPressed: () {
//               setState(() {
//                 isFav
//                     ? FavouriteManager.remove(item.id)
//                     : FavouriteManager.add(item.id);
//               });
//             },
//           ),

//           // chat only if not owner
//           if (!isOwner)
//             IconButton(
//               icon: const Icon(Icons.chat, color: Color(0xFF8A005D), size: 28),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChatScreen(
//                       personUid: item.ownerId,
//                       personName: ownerName,
//                     ),
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   Widget buildOwnerSection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         children: [
//           const Icon(Icons.person, color: Color(0xFF8A005D)),
//           const SizedBox(width: 8),
//           Text("Owner: $ownerName"),
//         ],
//       ),
//     );
//   }

//   Widget buildDescription(Item item) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Text(item.description,
//           style: const TextStyle(fontSize: 15, color: Colors.black87)),
//     );
//   }

//   Widget buildRatingSection(Item item) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
//       child: Row(
//         children: [
//           Icon(Icons.star, color: Colors.amber[700], size: 22),
//           const SizedBox(width: 4),
//           Text("${item.averageRating.toStringAsFixed(1)} (${item.ratingCount})"),
//         ],
//       ),
//     );
//   }

//   // RENTAL CHIPS
//   Widget buildRentalChips(List<String> periods, Item item) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Wrap(
//         spacing: 8,
//         children: periods.map((p) {
//           return ChoiceChip(
//             label: Text("$p (JOD ${item.rentalPeriods[p]})"),
//             selected: selectedPeriod == p,
//             onSelected: (_) {
//               setState(() {
//                 selectedPeriod = p;
//                 startDate = null;
//                 endDate = null;
//                 startTime = null;
//                 count = 1;
//                 pickupTime = null;
//               });
//             },
//             selectedColor: const Color(0xFF8A005D),
//             labelStyle: TextStyle(
//               color: selectedPeriod == p ? Colors.white : Colors.black,
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // RENTAL SELECTOR
//   Widget buildRentalSelector(Item item) {
//     if (selectedPeriod == null) return const SizedBox.shrink();
//     final p = selectedPeriod!.toLowerCase();

//     if (p == "hourly") return buildHourlySelector();

//     return buildDaySelector();
//   }

//   Widget buildHourlySelector() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

//           buildDatePicker("Start Date", startDate, (d) {
//             setState(() {
//               startDate = d;
//               calculateEndDate();
//             });
//           }),

//           const SizedBox(height: 16),

//           buildTimePicker("Start Time", startTime, (t) {
//             setState(() {
//               startTime = t;
//               calculateEndDate();
//             });
//           }),

//           const SizedBox(height: 22),

//           const Text(
//             "Number of Hours",
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 10),

//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     if (count > 1) {
//                       setState(() {
//                         count--;
//                         calculateEndDate();
//                       });
//                     }
//                   },
//                   child: const Icon(Icons.remove,
//                       color: Color(0xFF8A005D), size: 26),
//                 ),

//                 Text(
//                   "$count Hours",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF8A005D),
//                   ),
//                 ),

//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       count++;
//                       calculateEndDate();
//                     });
//                   },
//                   child: const Icon(Icons.add,
//                       color: Color(0xFF8A005D), size: 26),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildDaySelector() {
//     String unitLabel = "Days";
//     final p = selectedPeriod?.toLowerCase();
//     if (p == "weekly") unitLabel = "Weeks";
//     if (p == "monthly") unitLabel = "Months";
//     if (p == "yearly") unitLabel = "Years";

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           buildDatePicker("Start Date", startDate, (d) {
//             setState(() {
//               startDate = d;
//               calculateEndDate();
//             });
//           }),
//           const SizedBox(height: 22),
//           Text(
//             "Number of $unitLabel",
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     if (count > 1) {
//                       setState(() {
//                         count--;
//                         calculateEndDate();
//                       });
//                     }
//                   },
//                   child: const Icon(Icons.remove,
//                       color: Color(0xFF8A005D), size: 26),
//                 ),
//                 Text(
//                   "$count $unitLabel",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF8A005D),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       count++;
//                       calculateEndDate();
//                     });
//                   },
//                   child:
//                   const Icon(Icons.add, color: Color(0xFF8A005D), size: 26),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildAvailabilityHint() {
//     if (loadingAvailability) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (unavailableRanges.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(16),
//         child: Text(
//           "✅ Fully available",
//           style: TextStyle(color: Colors.green),
//         ),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Unavailable Periods",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           ...unavailableRanges.map((r) => Text(
//             "❌ ${DateFormat('MMM d, HH:mm').format(r.start)}"
//                 " → ${DateFormat('MMM d, HH:mm').format(r.end)}",
//             style: const TextStyle(color: Colors.red),
//           )),
//         ],
//       ),
//     );
//   }

//   Widget buildDatePicker(
//       String title, DateTime? value, Function(DateTime) onSelect) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 4, bottom: 4),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//         ),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: () async {
//               final pick = await showDatePicker(
//                 context: context,
//                 initialDate: DateTime.now(),
//                 firstDate: DateTime.now(),
//                 lastDate: DateTime(2030),
//               );
//               if (pick != null) onSelect(pick);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF8A005D),
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text(
//               value == null
//                   ? "Select Start Date"
//                   : DateFormat("yyyy-MM-dd").format(value),
//               style: const TextStyle(fontSize: 15),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildTimePicker(
//       String title, TimeOfDay? value, Function(TimeOfDay) onSelect) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title,
//             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 6),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: () async {
//               final pick =
//               await showTimePicker(context: context, initialTime: TimeOfDay.now());
//               if (pick != null) onSelect(pick);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF8A005D),
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text(value == null ? "Select Time" : value.format(context)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildEndDateDisplay() {
//     if (endDate == null) return const SizedBox.shrink();

//     final isHourly = selectedPeriod?.toLowerCase() == "hourly";

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//       child: Text(
//         isHourly
//             ? "End Date & Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endDate!)}"
//             : "End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}",
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF8A005D),
//         ),
//       ),
//     );
//   }

//   Widget buildTotalPrice(Item item) {
//     if (selectedPeriod == null) return const SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Text(
//         "Total Price: JOD ${computeTotalPrice(item).toStringAsFixed(2)}",
//         style: const TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF8A005D),
//         ),
//       ),
//     );
//   }

//   Widget buildPickupSelector() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(left: 4, bottom: 4),
//             child: Text(
//               "Pickup Time",
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//           ),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () async {
//                 final pick = await showTimePicker(
//                     context: context, initialTime: TimeOfDay.now());
//                 if (pick != null) setState(() => pickupTime = pick.format(context));
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF8A005D),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: Text(
//                 pickupTime == null ? "Select Pickup Time" : pickupTime!,
//                 style: const TextStyle(fontSize: 15),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildRentButton(Item item) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF8A005D),
//           minimumSize: const Size(double.infinity, 55),
//         ),
//         onPressed: () async {
//           calculateEndDate();

//           if (selectedPeriod == null ||
//               startDate == null ||
//               endDate == null ||
//               pickupTime == null ||
//               (selectedPeriod!.toLowerCase() == "hourly" &&
//                   startTime == null)) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                   content: Text("Please complete all fields")),
//             );
//             return;
//           }

//           final isHourly =
//               selectedPeriod!.toLowerCase() == "hourly";

//           final data = {
//             "itemId": item.id,
//             "itemTitle": item.name,
//             "itemOwnerUid": item.ownerId,
//             "customerUid": UserManager.uid,
//             "status": "pending",
//             "rentalType": selectedPeriod,
//             "rentalQuantity": count,
//             "startDate": startDate!.toIso8601String(),
//             "endDate": endDate!.toIso8601String(),
//             "startTime":
//             isHourly ? startTime!.format(context) : null,
//             "endTime": isHourly
//                 ? TimeOfDay.fromDateTime(endDate!)
//                 .format(context)
//                 : null,
//             "pickupTime": pickupTime,
//             "totalPrice": computeTotalPrice(item),
//           };

//           try {
//             await FirestoreService.createRentalRequest(data);

//             if (!mounted) return;

//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("Rental request submitted"),
//                 backgroundColor: Colors.green,
//               ),
//             );

//             Navigator.pushNamed(context, "/orders");

//           } on FirebaseFunctionsException catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(e.message ?? "Something went wrong"),
//                 backgroundColor: Colors.red,
//               ),
//             );

//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("Unexpected error. Please try again."),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }

//         },
//         child: const Text(
//           "Rent Now",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   // REVIEWS
//   Widget buildReviewsSection(Item item) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Reviews",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           if (topReviews.isEmpty)
//             const Text(
//               "No reviews yet",
//               style: TextStyle(fontSize: 14, color: Colors.black54),
//             )
//           else
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: topReviews.map((rev) {
//                 return Container(
//                   width: double.infinity,
//                   margin: const EdgeInsets.only(bottom: 12),
//                   padding: const EdgeInsets.all(12),
//                   constraints: const BoxConstraints(maxWidth: 350),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.grey.shade300, width: 1),
//                     color: Colors.white,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.star, color: Colors.amber[700], size: 20),
//                           const SizedBox(width: 6),
//                           Text("${rev['rating']}"),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         rev['review'],
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           const SizedBox(height: 6),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => AllReviewsPage(itemId: item.id),
//                   ),
//                 );
//               },
//               child: const Text("Show All Reviews →"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // MAP
//   Widget buildMapSection(Item item) {
//     if (item.latitude == null || item.longitude == null) {
//       return Container(
//         height: 150,
//         margin: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Center(
//           child: Text(
//             "📍 Location not provided",
//             style: TextStyle(fontSize: 16, color: Colors.black54),
//           ),
//         ),
//       );
//     }

//     return Container(
//       height: 200,
//       margin: const EdgeInsets.all(20),
//       child: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: LatLng(item.latitude!, item.longitude!),
//           zoom: 14,
//         ),
//         markers: {
//           Marker(
//             markerId: const MarkerId("itemLoc"),
//             position: LatLng(item.latitude!, item.longitude!),
//           )
//         },
//       ),
//     );
//   }
// }
