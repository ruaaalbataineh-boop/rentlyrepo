import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2/ChatScreen.dart';
import 'Orders.dart';
import 'EquipmentItem.dart';
import 'Favourite.dart';

class EquipmentDetailPage extends StatefulWidget {
  static const routeName = '/product-details';
  const EquipmentDetailPage({super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  bool isFavoritePressed = false;
  int _currentPage = 0;
  
  RentalType selectedRentalType = RentalType.hourly;

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? pickupTime;
  
  int numberOfDays = 1; 
  int numberOfWeeks = 1; 
  int numberOfMonths = 1; 
  int numberOfYears = 1;

  bool isLiked = false;
  int likesCount = 0;

  double userRating = 0.0;
  final TextEditingController reviewController = TextEditingController();
  List<String> reviews = [];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
   
          if (selectedRentalType == RentalType.hourly) {
            endDate = picked;
          }
        
          _updateEndDateFromPeriod();
        } else {
          if (startDate == null || picked.isBefore(startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date must be after start date'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          endDate = picked;
          _autoAdjustRentalType();
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
         
          if (selectedRentalType == RentalType.hourly && 
              startTime != null && 
              endTime != null &&
              startDate == endDate) {
            final startDateTime = TimeOfDay(hour: startTime!.hour, minute: startTime!.minute);
            final endDateTime = TimeOfDay(hour: endTime!.hour, minute: endTime!.minute);
            
            final startMinutes = startDateTime.hour * 60 + startDateTime.minute;
            final endMinutes = endDateTime.hour * 60 + endDateTime.minute;
            
            if (endMinutes <= startMinutes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('End time must be after start time'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
          }
          _autoAdjustRentalType();
        }
      });
    }
  }

  void _updateEndDateFromPeriod() {
    if (startDate != null && selectedRentalType != RentalType.hourly) {
      setState(() {
        Duration duration = Duration();
        
        switch (selectedRentalType) {
          case RentalType.daily:
            duration = Duration(days: numberOfDays);
            break;
          case RentalType.weekly:
            duration = Duration(days: numberOfWeeks * 7);
            break;
          case RentalType.monthly:
            duration = Duration(days: numberOfMonths * 30);
            break;
          case RentalType.yearly:
            duration = Duration(days: numberOfYears * 365);
            break;
          case RentalType.hourly:
           
            break;
        }
        
        endDate = startDate!.add(duration);
        _autoAdjustRentalType();
      });
    }
  }

  void _clearAllSelections() {
    setState(() {
      startDate = null;
      endDate = null;
      startTime = null;
      endTime = null;
      pickupTime = null;
      numberOfDays = 1;
      numberOfWeeks = 1;
      numberOfMonths = 1;
      numberOfYears = 1;
    });
  }

  void _clearTimeSelections() {
    setState(() {
      startTime = null;
      endTime = null;
    });
  }

  void _autoAdjustRentalType() {
    if (startDate == null || endDate == null) return;
    
    double totalHours = _calculateTotalHours();
    
    if (!_isValidRentalTypeForDuration()) {
      RentalType requiredType = RentalType.hourly;
      String typeName = "Hourly";
      
      if (totalHours > 24 * 365) {
        requiredType = RentalType.yearly;
        typeName = "Yearly";
      } else if (totalHours > 24 * 30) {
        requiredType = RentalType.monthly;
        typeName = "Monthly";
      } else if (totalHours > 24 * 6) {
        requiredType = RentalType.weekly;
        typeName = "Weekly";
      } else if (totalHours > 24) {
        requiredType = RentalType.daily;
        typeName = "Daily";
      }
      
      if (selectedRentalType != requiredType) {
        _updateRentalType(requiredType, typeName);
      }
    }
  }

  void _updateRentalType(RentalType newType, String typeName) {
    if (selectedRentalType != newType) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rental type changed to $typeName based on selected duration'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() {
        selectedRentalType = newType;
        
        if (newType != RentalType.hourly) {
          startTime = null;
          endTime = null;
      
          numberOfDays = 1;
          numberOfWeeks = 1;
          numberOfMonths = 1;
          numberOfYears = 1;
          if (startDate != null) {
            _updateEndDateFromPeriod();
          }
        } else {
    
          if (startDate != null) {
            endDate = startDate;
          }
        }
      });
    }
  }

  double _calculateTotalHours() {
    if (startDate == null || endDate == null) return 0.0;
    
    DateTime startDateTime;
    DateTime endDateTime;
    
    if (selectedRentalType == RentalType.hourly && startTime != null && endTime != null) {
      startDateTime = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );
      
      endDateTime = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        endTime!.hour,
        endTime!.minute,
      );
    } else {
      startDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day);
      endDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59);
    }
    
    if (endDateTime.isBefore(startDateTime)) return 0.0;
    
    return endDateTime.difference(startDateTime).inHours.toDouble();
  }

  bool _isValidRentalTypeForDuration() {
    if (startDate == null || endDate == null) return true;
    
    double totalHours = _calculateTotalHours();
    
    switch (selectedRentalType) {
      case RentalType.hourly:
        return totalHours <= 24 && totalHours > 0;
      case RentalType.daily:
        return totalHours <= 24 * 6;
      case RentalType.weekly:
        return totalHours <= 24 * 30;
      case RentalType.monthly:
        return totalHours <= 24 * 365;
      case RentalType.yearly:
        return totalHours > 24 * 365; 
    }
  }

  String _getRentalTypeErrorMessage() {
    if (!_isValidRentalTypeForDuration()) {
      double totalHours = _calculateTotalHours();
      
      if (selectedRentalType == RentalType.hourly) {
        if (totalHours <= 0) {
          return "End time must be after start time";
        } else if (totalHours > 24) {
          return "Hourly rental is not allowed for more than 24 hours. Please select Daily rental.";
        }
      } else if (selectedRentalType == RentalType.daily && totalHours > 24 * 6) {
        return "Daily rental is not allowed for more than 6 days. Please select Weekly rental.";
      } else if (selectedRentalType == RentalType.weekly && totalHours > 24 * 30) {
        return "Weekly rental is not allowed for more than 30 days. Please select Monthly rental.";
      } else if (selectedRentalType == RentalType.monthly && totalHours > 24 * 365) {
        return "Monthly rental is not allowed for more than 365 days. Please select Yearly rental.";
      }
    }
    return "";
  }

  double calculateTotalPrice(EquipmentItem equipment) {
    if (!_isValidRentalTypeForDuration()) {
      return 0.0;
    }
    
    final basePrice = equipment.getPriceForRentalType(selectedRentalType);
    
    bool hasAllRequiredData = false;
    
    switch (selectedRentalType) {
      case RentalType.hourly:
        hasAllRequiredData = startDate != null && 
                            startTime != null && 
                            endDate != null && 
                            endTime != null;
        break;
      case RentalType.daily:
      case RentalType.weekly:
      case RentalType.monthly:
      case RentalType.yearly:
        hasAllRequiredData = startDate != null && endDate != null;
        break;
    }
    
    if (!hasAllRequiredData) {
      return 0.0;
    }
    
    switch (selectedRentalType) {
      case RentalType.hourly:
        DateTime startDateTime = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
          startTime!.hour,
          startTime!.minute,
        );
        
        DateTime endDateTime = DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
          endTime!.hour,
          endTime!.minute,
        );
        
        if (endDateTime.isBefore(startDateTime)) {
          return 0.0;
        }
        
        final duration = endDateTime.difference(startDateTime);
        final totalMinutes = duration.inMinutes;
        
        if (totalMinutes <= 0) {
          return 0.0;
        }
        
        if (totalMinutes <= 60) {
          return basePrice;
        }
        
        final totalHours = (totalMinutes / 60).ceilToDouble();
        return basePrice * totalHours;
        
      case RentalType.daily:
        if (endDate!.isBefore(startDate!)) {
          return 0.0;
        }
        
        final difference = endDate!.difference(startDate!);
        final days = difference.inDays;
        
        if (days == 0) {
          return basePrice;
        }
        
        final totalDays = difference.inHours % 24 > 0 ? days + 1 : days;
        return basePrice * totalDays;
        
      case RentalType.weekly:
        if (endDate!.isBefore(startDate!)) {
          return 0.0;
        }
        
        final difference = endDate!.difference(startDate!);
        final days = difference.inDays;
        
        final weeks = (days / 7).ceilToDouble();
        return basePrice * weeks;
        
      case RentalType.monthly:
        if (endDate!.isBefore(startDate!)) {
          return 0.0;
        }
        
        final difference = endDate!.difference(startDate!);
        final days = difference.inDays;
        
        final months = (days / 30).ceilToDouble();
        return basePrice * months;
        
      case RentalType.yearly:
        if (endDate!.isBefore(startDate!)) {
          return 0.0;
        }
        
        final difference = endDate!.difference(startDate!);
        final days = difference.inDays;
        
        final years = (days / 365).ceilToDouble();
        return basePrice * years;
    }
  }

  void _showReviewDialog() {
    String newReview = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setStateSB) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Write a Review",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                
                    TextField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Write your review here...",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        newReview = value;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
            
                    if (reviews.isNotEmpty) ...[
                      const Text(
                        "Previous Reviews:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                reviews[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (newReview.trim().isNotEmpty) {
                                setState(() {
                                  reviews.add(newReview);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Review added successfully"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8A005D),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Submit",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipment =
        ModalRoute.of(context)?.settings.arguments as EquipmentItem?;

    if (equipment == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No product data provided!",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
    }

    isFavoritePressed = FavouriteManager.favouriteItems.contains(equipment);
    final totalPrice = calculateTotalPrice(equipment);
    final errorMessage = _getRentalTypeErrorMessage();
    final isValidRentalType = _isValidRentalTypeForDuration();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 280,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    PageView.builder(
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Icon(
                            equipment.icon,
                            size: 140,
                            color: const Color(0xFF8A005D),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.black87, size: 26),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isFavoritePressed) {
                              isFavoritePressed = false;
                              FavouriteManager.remove(equipment);
                            } else {
                              isFavoritePressed = true;
                              FavouriteManager.add(equipment);
                            }
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavoritePressed
                                    ? '${equipment.title} added to Favorites'
                                    : '${equipment.title} removed from Favorites',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.favorite,
                          color: isFavoritePressed ? Colors.red : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? const Color(0xFF8A005D)
                                  : Colors.grey,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            equipment.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87
                            ),
                          ),
                        ),
                       IconButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chat with Owner"),
          content: const Text("Do you want to chat with the owner?"),
          actions: [
            TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Yes"),
              onPressed: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      personName: equipment.ownerName,
                      personUid: equipment.ownerUid,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  },
  icon: const Icon(
    Icons.help_outline,
    color: Color(0xFF8A005D),
    size: 28,
  ),
  tooltip: "Ask the owner",
),
                      ],
                    ),
                    const SizedBox(height: 10),

                
                    Row(
                      children: [
                    
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                double tempRating = userRating;
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(20),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.9,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: StatefulBuilder(
                                      builder: (context, setStateSB) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "Rate this product",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(5, (index) {
                                                return IconButton(
                                                  onPressed: () {
                                                    setStateSB(() {
                                                      tempRating = (index + 1).toDouble();
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.star,
                                                    color: (index + 1) <= tempRating
                                                        ? Colors.amber
                                                        : Colors.grey,
                                                    size: 40,
                                                  ),
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                    ),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        userRating = tempRating;
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF8A005D),
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                    ),
                                                    child: const Text(
                                                      "OK",
                                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber[700], size: 22),
                              const SizedBox(width: 4),
                              Text("$userRating",
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                    
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLiked = !isLiked;
                              likesCount = isLiked ? 1 : 0;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up,
                                color: isLiked ? Colors.green : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text("$likesCount",
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
              
                        GestureDetector(
                          onTap: _showReviewDialog,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reviews,
                                color: Colors.blue,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text("${reviews.length}",
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Rental Period:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (startDate != null || startTime != null || endDate != null || endTime != null)
                              TextButton(
                                onPressed: _clearAllSelections,
                                child: const Row(
                                  children: [
                                    Icon(Icons.clear, size: 16, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text(
                                      "Clear All",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRentalTypeChip("Hourly", RentalType.hourly, equipment),
                              const SizedBox(width: 8),
                              _buildRentalTypeChip("Daily", RentalType.daily, equipment),
                              const SizedBox(width: 8),
                              _buildRentalTypeChip("Weekly", RentalType.weekly, equipment),
                              const SizedBox(width: 8),
                              _buildRentalTypeChip("Monthly", RentalType.monthly, equipment),
                              const SizedBox(width: 8),
                              _buildRentalTypeChip("Yearly", RentalType.yearly, equipment),
                            ],
                          ),
                        ),
                        if (!isValidRentalType && errorMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[800], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total: JOD ${totalPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: totalPrice > 0 && isValidRentalType
                                      ? const Color(0xFF8A005D) 
                                      : Colors.grey,
                                ),
                              ),
                              if (totalPrice == 0 && (startDate != null || startTime != null || endDate != null || endTime != null)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _getIncompleteMessage(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    Column(
                      children: [
                        if (selectedRentalType == RentalType.hourly)
                          _buildDateButton(
                            "Date",
                            startDate == null
                                ? "Select Date"
                                : DateFormat('yyyy-MM-dd').format(startDate!),
                            () => _selectDate(context, true),
                            startDate != null,
                            onClear: () => setState(() {
                              startDate = null;
                              endDate = null;
                              startTime = null;
                              endTime = null;
                            }),
                          )
                        else
                          _buildDateButton(
                            "Start Date",
                            startDate == null
                                ? "Select Start Date"
                                : DateFormat('yyyy-MM-dd').format(startDate!),
                            () => _selectDate(context, true),
                            startDate != null,
                            onClear: () => setState(() {
                              startDate = null;
                              endDate = null;
                              numberOfDays = 1;
                              numberOfWeeks = 1;
                              numberOfMonths = 1;
                              numberOfYears = 1;
                            }),
                          ),
                        
                        const SizedBox(height: 10),
                        
                    
                        if (selectedRentalType != RentalType.hourly) 
                          _buildPeriodSelector(),
                        
                        if (selectedRentalType == RentalType.hourly) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeButton(
                                  "Start Time",
                                  startTime == null
                                      ? "Select Start Time"
                                      : startTime!.format(context),
                                  () => _selectTime(context, true),
                                  startTime != null,
                                  onClear: () => setState(() => startTime = null),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTimeButton(
                                  "End Time",
                                  endTime == null
                                      ? "Select End Time"
                                      : endTime!.format(context),
                                  () => _selectTime(context, false),
                                  endTime != null,
                                  onClear: () => setState(() => endTime = null),
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 10),
                        
                        _buildPickupTimeButton(),
                        
                        const SizedBox(height: 10),
                       
                        if (_hasSelectedPeriod())
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A005D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF8A005D)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Color(0xFF8A005D)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getRentalPeriodDescription(),
                                        style: const TextStyle(
                                          color: Color(0xFF8A005D),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (startDate != null && endDate != null)
                                  const SizedBox(height: 4),
                                if (startDate != null && endDate != null)
                                  Text(
                                    selectedRentalType == RentalType.hourly
                                        ? "Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}"
                                        : "From: ${DateFormat('yyyy-MM-dd').format(startDate!)} To: ${DateFormat('yyyy-MM-dd').format(endDate!)}",
                                    style: const TextStyle(
                                      color: Color(0xFF8A005D),
                                      fontSize: 12,
                                    ),
                                  ),
                                if (selectedRentalType != RentalType.hourly && startDate != null)
                                  const SizedBox(height: 4),
                                if (selectedRentalType != RentalType.hourly && startDate != null)
                                  Text(
                                    _getDurationDescription(),
                                    style: const TextStyle(
                                      color: Color(0xFF8A005D),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isSelectionComplete() && pickupTime != null && isValidRentalType && totalPrice > 0 ? () {
                        OrdersManager.addOrder(equipment);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${equipment.title} added to Orders'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        Future.delayed(
                            const Duration(milliseconds: 300), () {
                          Navigator.pushNamed(context, '/orders');
                        });
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSelectionComplete() && pickupTime != null && isValidRentalType && totalPrice > 0
                            ? const Color(0xFF8A005D) 
                            : Colors.grey[400],
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSelectionComplete() && pickupTime != null && isValidRentalType && totalPrice > 0
                            ? "Rent Now (JOD ${totalPrice.toStringAsFixed(2)})" 
                            : "Select all options to rent",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: _isSelectionComplete() && pickupTime != null && isValidRentalType && totalPrice > 0
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            equipment.latitude ?? 32.55,
                            equipment.longitude ?? 35.85,
                          ),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("itemLocation"),
                            position: LatLng(
                              equipment.latitude ?? 32.55,
                              equipment.longitude ?? 35.85,
                            ),
                            infoWindow: const InfoWindow(
                                title: "Equipment Location"),
                            icon:
                                BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
                        },
                        myLocationEnabled: false,
                        zoomControlsEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String title, String text, VoidCallback onPressed, bool isSelected, {VoidCallback? onClear}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF8A005D) : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.grey[700],
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String title, String text, VoidCallback onPressed, bool isSelected, {VoidCallback? onClear}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF8A005D) : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.grey[700],
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    switch (selectedRentalType) {
      case RentalType.daily:
        return _buildDailySelector();
      case RentalType.weekly:
        return _buildWeeklySelector();
      case RentalType.monthly:
        return _buildMonthlySelector();
      case RentalType.yearly:
        return _buildYearlySelector();
      case RentalType.hourly:
        return Container();
    }
  }

  Widget _buildDailySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Number of Days",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (numberOfDays > 1) {
                    setState(() {
                      numberOfDays--;
                      _updateEndDateFromPeriod();
                    });
                  }
                },
                icon: const Icon(Icons.remove, color: Color(0xFF8A005D)),
              ),
              Expanded(
                child: Text(
                  "$numberOfDays Day${numberOfDays > 1 ? 's' : ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A005D),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    numberOfDays++;
                    _updateEndDateFromPeriod();
                  });
                },
                icon: const Icon(Icons.add, color: Color(0xFF8A005D)),
              ),
            ],
          ),
        ),
        if (startDate != null && numberOfDays > 0)
          const SizedBox(height: 8),
        if (startDate != null && numberOfDays > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "End Date: ${DateFormat('yyyy-MM-dd').format(startDate!.add(Duration(days: numberOfDays)))}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Number of Weeks",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (numberOfWeeks > 1) {
                    setState(() {
                      numberOfWeeks--;
                      _updateEndDateFromPeriod();
                    });
                  }
                },
                icon: const Icon(Icons.remove, color: Color(0xFF8A005D)),
              ),
              Expanded(
                child: Text(
                  "$numberOfWeeks Week${numberOfWeeks > 1 ? 's' : ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A005D),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    numberOfWeeks++;
                    _updateEndDateFromPeriod();
                  });
                },
                icon: const Icon(Icons.add, color: Color(0xFF8A005D)),
              ),
            ],
          ),
        ),
        if (startDate != null && numberOfWeeks > 0)
          const SizedBox(height: 8),
        if (startDate != null && numberOfWeeks > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "End Date: ${DateFormat('yyyy-MM-dd').format(startDate!.add(Duration(days: numberOfWeeks * 7)))}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Number of Months",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (numberOfMonths > 1) {
                    setState(() {
                      numberOfMonths--;
                      _updateEndDateFromPeriod();
                    });
                  }
                },
                icon: const Icon(Icons.remove, color: Color(0xFF8A005D)),
              ),
              Expanded(
                child: Text(
                  "$numberOfMonths Month${numberOfMonths > 1 ? 's' : ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A005D),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    numberOfMonths++;
                    _updateEndDateFromPeriod();
                  });
                },
                icon: const Icon(Icons.add, color: Color(0xFF8A005D)),
              ),
            ],
          ),
        ),
        if (startDate != null && numberOfMonths > 0)
          const SizedBox(height: 8),
        if (startDate != null && numberOfMonths > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "End Date: ${DateFormat('yyyy-MM-dd').format(startDate!.add(Duration(days: numberOfMonths * 30)))}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYearlySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Number of Years",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (numberOfYears > 1) {
                    setState(() {
                      numberOfYears--;
                      _updateEndDateFromPeriod();
                    });
                  }
                },
                icon: const Icon(Icons.remove, color: Color(0xFF8A005D)),
              ),
              Expanded(
                child: Text(
                  "$numberOfYears Year${numberOfYears > 1 ? 's' : ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A005D),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    numberOfYears++;
                    _updateEndDateFromPeriod();
                  });
                },
                icon: const Icon(Icons.add, color: Color(0xFF8A005D)),
              ),
            ],
          ),
        ),
        if (startDate != null && numberOfYears > 0)
          const SizedBox(height: 8),
        if (startDate != null && numberOfYears > 0)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "End Date: ${DateFormat('yyyy-MM-dd').format(startDate!.add(Duration(days: numberOfYears * 365)))}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPickupTimeButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pickup Time",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pickupTime != null)
              GestureDetector(
                onTap: () => setState(() => pickupTime = null),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                pickupTime = picked.format(context);
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: pickupTime != null ? const Color(0xFF8A005D) : Colors.grey[200],
            foregroundColor: pickupTime != null ? Colors.white : Colors.grey[700],
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(
            pickupTime == null
                ? "Select Pickup Time"
                : "Pickup at $pickupTime",
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalTypeChip(String label, RentalType type, EquipmentItem equipment) {
    bool isSelected = selectedRentalType == type;
    bool isValidForDuration = _isValidRentalTypeForDuration() || !_hasSelectedPeriod();
    
    return ChoiceChip(
      label: Text("$label (JOD ${equipment.getPriceForRentalType(type).toStringAsFixed(2)})"),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            if (isSelected == false) {
              if (selectedRentalType == RentalType.hourly && type != RentalType.hourly) {
                _clearTimeSelections();
        
                numberOfDays = 1;
                numberOfWeeks = 1;
                numberOfMonths = 1;
                numberOfYears = 1;
                if (startDate != null) {
                  _updateEndDateFromPeriod();
                }
              } else if (selectedRentalType != RentalType.hourly && type == RentalType.hourly) {
                _clearAllSelections();
              } else if (selectedRentalType != RentalType.hourly && type != RentalType.hourly) {
      
                numberOfDays = 1;
                numberOfWeeks = 1;
                numberOfMonths = 1;
                numberOfYears = 1;
                if (startDate != null) {
                  _updateEndDateFromPeriod();
                }
              }
            }
            selectedRentalType = type;
            
        
            if (type == RentalType.hourly && startDate != null) {
              endDate = startDate;
            }
          });
        }
      },
      selectedColor: const Color(0xFF8A005D),
      backgroundColor: isValidForDuration ? null : Colors.grey[300],
      disabledColor: Colors.grey[300],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isValidForDuration ? Colors.black : Colors.grey),
      ),
    );
  }
  
  bool _isSelectionComplete() {
    switch (selectedRentalType) {
      case RentalType.hourly:
        return startDate != null && startTime != null && endTime != null;
      default:
        return startDate != null && endDate != null;
    }
  }
  
  String _getIncompleteMessage() {
    if (selectedRentalType == RentalType.hourly) {
      if (startDate == null) return "Missing: Date";
      if (startTime == null) return "Missing: Start Time";
      if (endTime == null) return "Missing: End Time";
    } else {
      if (startDate == null) return "Missing: Start Date";
      if (endDate == null) return "Missing: End Date";
    }
    return "";
  }
  
  bool _hasSelectedPeriod() {
    switch (selectedRentalType) {
      case RentalType.hourly:
        return startDate != null && startTime != null && endTime != null;
      default:
        return startDate != null && endDate != null;
    }
  }
  
  String _getRentalPeriodDescription() {
    if (selectedRentalType == RentalType.hourly) {
      if (startDate != null && startTime != null && endTime != null) {
        final startDateTime = TimeOfDay(hour: startTime!.hour, minute: startTime!.minute);
        final endDateTime = TimeOfDay(hour: endTime!.hour, minute: endTime!.minute);
        

        final startMinutes = startDateTime.hour * 60 + startDateTime.minute;
        final endMinutes = endDateTime.hour * 60 + endDateTime.minute;
        
        if (endMinutes <= startMinutes) {
          return "Invalid time selection";
        }
        
        final totalMinutes = endMinutes - startMinutes;
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        
        return "Rental period: $hours hour(s) ${minutes > 0 ? 'and $minutes minute(s)' : ''}";
      }
    } else {
      if (startDate != null && endDate != null) {
        final days = endDate!.difference(startDate!).inDays;
        return "Rental period: $days day(s)";
      }
    }
    return "";
  }
  
  String _getDurationDescription() {
    switch (selectedRentalType) {
      case RentalType.daily:
        return "Duration: $numberOfDays Day${numberOfDays > 1 ? 's' : ''}";
      case RentalType.weekly:
        return "Duration: $numberOfWeeks Week${numberOfWeeks > 1 ? 's' : ''}";
      case RentalType.monthly:
        return "Duration: $numberOfMonths Month${numberOfMonths > 1 ? 's' : ''}";
      case RentalType.yearly:
        return "Duration: $numberOfYears Year${numberOfYears > 1 ? 's' : ''}";
      case RentalType.hourly:
        return "";
    }
  }
}

