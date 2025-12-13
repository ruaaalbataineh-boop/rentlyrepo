import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:p2/services/firestore_service.dart';
import 'package:p2/services/rental_logic.dart';
import 'package:p2/user_manager.dart';
import 'Item.dart';
import 'FavouriteManager.dart';
import 'Orders.dart';
import 'ChatScreen.dart';
import 'AllReviewsPage.dart';
import 'package:p2/models/rental_request.dart';

class EquipmentDetailPage extends StatefulWidget {
  static const routeName = '/product-details';
  const EquipmentDetailPage({super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  // IMAGE SLIDER INDEX
  int currentPage = 0;

  // OWNER NAME
  String ownerName = "Loading...";

  // RENTAL SELECTION
  String? selectedPeriod;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int count = 1;
  String? pickupTime;

  // REVIEWS PREVIEW
  List<Map<String, dynamic>> topReviews = [];
  double userRating = 0;

  @override
  void initState() {
    super.initState();
  }

  // LOAD OWNER NAME FROM REALTIME DATABASE
  Future<void> loadOwnerName(String uid) async {
    final snap = await FirebaseDatabase.instance.ref("users/$uid/name").get();
    setState(() {
      ownerName = snap.exists ? snap.value.toString() : "Owner";
    });
  }

  // FETCH TOP 3 REVIEWS
  Future<void> loadTopReviews(String itemId) async {
    final snap = await FirebaseDatabase.instance
        .ref("reviews/$itemId")
        .limitToFirst(3)
        .get();

    if (snap.exists) {
      List<Map<String, dynamic>> list = [];
      for (var child in snap.children) {
        list.add({
          "rating": child.child("rating").value ?? 0,
          "review": child.child("review").value ?? "",
          "userId": child.child("userId").value ?? "",
        });
      }

      setState(() {
        topReviews = list;
      });
    }
  }

  // AUTO CALCULATE END DATE (Daily/Weekly/Monthly/Yearly)
  void calculateEndDate() {
    if (startDate == null || selectedPeriod == null) {
      endDate = null;
      return;
    }

    int daysToAdd = 0;
    final p = selectedPeriod!.toLowerCase();

    if (p == "daily") daysToAdd = count;
    else if (p == "weekly") daysToAdd = count * 7;
    else if (p == "monthly") daysToAdd = count * 30;
    else if (p == "yearly") daysToAdd = count * 365;

    endDate = startDate!.add(Duration(days: daysToAdd));
  }

  // PRICE CALCULATOR
  double computeTotalPrice(Item item) {

    if (selectedPeriod == null) return 0;

    double base = double.tryParse("${item.rentalPeriods[selectedPeriod]}") ?? 0;

    if (selectedPeriod!.toLowerCase() == "hourly") {
      if (startTime != null && endTime != null) {
        int minutes = (endTime!.hour * 60 + endTime!.minute) -
            (startTime!.hour * 60 + startTime!.minute);
        if (minutes > 0) {
          return base * (minutes / 60).ceil();
        }
      }
      return base;
    }

    return base * count;
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as Item;

    loadOwnerName(item.ownerId);
    loadTopReviews(item.id);

    final periods = item.rentalPeriods.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTopHeader(context, "Item Details"),
              buildImageSlider(item.images),
              buildHeader(item),
              buildOwnerSection(),
              buildDescription(item),
              buildRatingSection(item),
              buildRentalChips(periods, item),
              buildRentalSelector(item),
              buildEndDateDisplay(),
              buildTotalPrice(item),
              buildPickupSelector(),
              buildRentButton(item),
              buildReviewsSection(item),
              buildMapSection(item),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTopHeader(BuildContext context, String title) {
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

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  // IMAGE SLIDER
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

  // HEADER
  Widget buildHeader(Item item) {
    final isFav = FavouriteManager.isFavourite(item.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name,
                style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),

          IconButton(
            icon: Icon(Icons.favorite,
                color: isFav ? Colors.red : Colors.grey, size: 30),
            onPressed: () {
              setState(() {
                isFav
                    ? FavouriteManager.remove(item.id)
                    : FavouriteManager.add(item.id);
              });
            },
          ),

          if (item.ownerId != UserManager.uid!)
            IconButton(
              icon:
              const Icon(Icons.chat, color: Color(0xFF8A005D), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(personUid: item.ownerId, personName: ownerName),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // OWNER
  Widget buildOwnerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF8A005D)),
          const SizedBox(width: 8),
          Text("Owner: $ownerName", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // DESCRIPTION
  Widget buildDescription(Item item) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(item.description,
          style: const TextStyle(fontSize: 15, color: Colors.black87)),
    );
  }

  // RATING
  Widget buildRatingSection(Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber[700], size: 22),
          const SizedBox(width: 4),
          Text("${item.averageRating.toStringAsFixed(1)} (${item.ratingCount})"),
        ],
      ),
    );
  }

  // RENTAL CHIPS
  Widget buildRentalChips(List<String> periods, Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        children: periods.map((p) {
          return ChoiceChip(
            label: Text("$p (JOD ${item.rentalPeriods[p]})"),
            selected: selectedPeriod == p,
            onSelected: (_) => setState(() {
              selectedPeriod = p;
              startDate = null;
              endDate = null;
              startTime = null;
              endTime = null;
              count = 1;
            }),
            selectedColor: const Color(0xFF8A005D),
            labelStyle: TextStyle(
              color: selectedPeriod == p ? Colors.white : Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }

  // RENTAL SELECTOR
  Widget buildRentalSelector(Item item) {
    if (selectedPeriod == null) return const SizedBox.shrink();

    final p = selectedPeriod!.toLowerCase();

    // HOURLY
    if (p == "hourly") return buildHourlySelector();

    // DAILY/WEEKLY/MONTHLY/YEARLY
    return buildDaySelector();
  }

  // HOURLY SELECTOR
  Widget buildHourlySelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          buildTimePicker("Start Time", startTime, (selected) {
            setState(() => startTime = selected);
          }),
          const SizedBox(height: 12),
          buildTimePicker("End Time", endTime, (selected) {
            setState(() => endTime = selected);
          }),
        ],
      ),
    );
  }

  // DAY SELECTOR
  Widget buildDaySelector() {
    // Determine the label for quantity based on rental period
    String unitLabel = "Days";
    if (selectedPeriod != null) {
      final p = selectedPeriod!.toLowerCase();
      if (p == "weekly") unitLabel = "Weeks";
      if (p == "monthly") unitLabel = "Months";
      if (p == "yearly") unitLabel = "Years";
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDatePicker("Start Date", startDate, (selected) {
            setState(() {
              startDate = selected;
              calculateEndDate();
            });
          }),

          const SizedBox(height: 22),

          const Text(
            "Number of Units",
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
                  child: const Icon(Icons.remove, color: Color(0xFF8A005D), size: 26),
                ),

                // COUNT + LABEL (center)
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

  // DATE PICKER
  Widget buildDatePicker(
      String title, DateTime? value, Function(DateTime) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // <-- Ensures left alignment
      children: [

        // LEFT-ALIGNED LABEL
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),

        // DATE PICK BUTTON
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
                  ? "Select Date"
                  : DateFormat("yyyy-MM-dd").format(value),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  // TIME PICKER
  Widget buildTimePicker(
      String title, TimeOfDay? value, Function(TimeOfDay) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () async {
            final pick =
            await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (pick != null) onSelect(pick);
          },
          child: Text(value == null ? "Select Time" : value.format(context)),
        ),
      ],
    );
  }

  // END DATE DISPLAY
  Widget buildEndDateDisplay() {
    if (endDate == null || selectedPeriod?.toLowerCase() == "hourly") {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        "End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8A005D),
        ),
      ),
    );
  }

  // TOTAL PRICE
  Widget buildTotalPrice(Item item) {
    if (selectedPeriod == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        "Total Price: JOD ${computeTotalPrice(item).toStringAsFixed(2)}",
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8A005D)),
      ),
    );
  }
// PICKUP TIME
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
              style: TextStyle(
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

  // RENT BUTTON
  Widget buildRentButton(Item item) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8A005D),
            minimumSize: const Size(double.infinity, 55)),
        onPressed: () async {
          if (selectedPeriod == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a rental period")),
            );
            return;
          }

          calculateEndDate(); // ensure it's updated

          if (startDate == null || endDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a start date")),
            );
            return;
          }

          final data = {
            "itemId": item.id,
            "itemTitle": item.name,
            "itemOwnerUid": item.ownerId,

            "rentalType": selectedPeriod!,
            "rentalQuantity": count,

            "startDate": startDate!.toIso8601String(),
            "endDate": endDate!.toIso8601String(),

            "pickupTime": pickupTime,
            "totalPrice": computeTotalPrice(item),

            // Only hourly
            "startTime": selectedPeriod == "Hourly" ? startTime?.format(context) : null,
            "endTime": selectedPeriod == "Hourly" ? endTime?.format(context) : null,
          };

          try {
            await FirestoreService.createRentalRequest(data);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Rental request submitted!")),
            );

            Navigator.pushNamed(context, "/orders");
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        },
        child: const Text("Rent Now",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
// REVIEWS
  Widget buildReviewsSection(Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // TITLE + NO REVIEWS + LINK LEFT
        children: [

          const Text(
            "Reviews",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // If NO reviews → LEFT aligned
          if (topReviews.isEmpty)
            const Text(
              "No reviews yet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
          else
          // Reviews exist → Center the card(s)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center, // CENTER CARDS
              children: topReviews.map((rev) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 350), // CENTERED WIDTH
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
              child: const Text(
                "Show All Reviews →",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MAP
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
            )),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(20),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
            target: LatLng(item.latitude!, item.longitude!), zoom: 14),
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
