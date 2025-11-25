// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intl/intl.dart';
// import 'Orders.dart';
// import 'EquipmentItem.dart';
// import 'Favourite.dart';
// import 'MapPage.dart';

// class EquipmentDetailPage extends StatefulWidget {
//   static const routeName = '/equipment-detail';
//   const EquipmentDetailPage({super.key});

//   @override
//   State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
// }

// class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
//   bool isFavoritePressed = false;
//   int _currentPage = 0;

//   DateTime? startDate;
//   DateTime? endDate;
//   String? pickupTime;

//   int likesCount = 0;

//   Future<void> _selectDate(BuildContext context, bool isStart) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2024),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           startDate = picked;
//         } else {
//           endDate = picked;
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final equipment =
//         ModalRoute.of(context)?.settings.arguments as EquipmentItem?;

//     if (equipment == null) {
//       return const Scaffold(
//         body: Center(
//           child: Text(
//             " No equipment data provided!",
//             style: TextStyle(fontSize: 20, color: Colors.red),
//           ),
//         ),
//       );
//     }

//     isFavoritePressed = FavouriteManager.favouriteItems.contains(equipment);
//     likesCount = likesCount == 0 ? equipment.likes : likesCount;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
             
//               Container(
//                 height: 280,
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: Stack(
//                   children: [
//                     PageView.builder(
//                       onPageChanged: (index) {
//                         setState(() => _currentPage = index);
//                       },
//                       itemCount: 3,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           color: Colors.white,
//                           alignment: Alignment.center,
//                           child: Icon(
//                             equipment.icon,
//                             size: 140,
//                             color: const Color(0xFF8A005D),
//                           ),
//                         );
//                       },
//                     ),
//                     Positioned(
//                       bottom: 10,
//                       left: 0,
//                       right: 0,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: List.generate(
//                           3,
//                           (index) => AnimatedContainer(
//                             duration: const Duration(milliseconds: 300),
//                             margin: const EdgeInsets.symmetric(horizontal: 4),
//                             width: _currentPage == index ? 10 : 8,
//                             height: _currentPage == index ? 10 : 8,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: _currentPage == index
//                                   ? const Color(0xFF8A005D)
//                                   : Colors.grey[400],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
                  
//                     Positioned(
//                       top: 20,
//                       left: 20,
//                       child: GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: const BoxDecoration(
//                             color: Colors.white70,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.arrow_back,
//                               color: Colors.black87, size: 26),
//                         ),
//                       ),
//                     ),
                   
//                     Positioned(
//                       top: 20,
//                       right: 20,
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             isFavoritePressed = !isFavoritePressed;
//                             if (isFavoritePressed) {
//                               FavouriteManager.add(equipment);
//                               likesCount++;
//                             } else {
//                               FavouriteManager.remove(equipment);
//                               if (likesCount > 0) likesCount--;
//                             }
//                           });
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 isFavoritePressed
//                                     ? '${equipment.title} added to Favorites'
//                                     : '${equipment.title} removed from Favorites',
//                               ),
//                               duration: const Duration(seconds: 1),
//                             ),
//                           );
//                         },
//                         child: Icon(
//                           Icons.favorite,
//                           color: isFavoritePressed ? Colors.red : Colors.grey,
//                           size: 30,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
             
//               Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       equipment.title,
//                       style: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Icon(Icons.star, color: Colors.amber[700], size: 22),
//                         const SizedBox(width: 4),
//                         Text("${equipment.rating}",
//                             style: const TextStyle(fontSize: 16)),
//                         Text(" (${equipment.reviews} reviews)",
//                             style: const TextStyle(
//                                 fontSize: 14, color: Colors.grey)),
//                         const SizedBox(width: 16),
//                         const Icon(Icons.thumb_up, color: Colors.green, size: 20),
//                         Text(" $likesCount",
//                             style: const TextStyle(fontSize: 14)),
//                         const SizedBox(width: 16),
//                         const Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
//                         Text(" ${equipment.rentedCount}",
//                             style: const TextStyle(fontSize: 14)),
//                       ],
//                     ),
//                     const SizedBox(height: 14),
//                     Text(
//                       "Rental Price: \$${equipment.pricePerDay * 7}/Week",
//                       style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF8A005D)),
//                     ),
//                     const SizedBox(height: 14),
//                     Text(
//                       equipment.description,
//                       style: const TextStyle(fontSize: 14, color: Colors.black54),
//                     ),
//                     const SizedBox(height: 14),
//                     Text("Release Year: ${equipment.releaseYear}",
//                         style:
//                             const TextStyle(fontSize: 14, color: Colors.black87)),
//                     const SizedBox(height: 14),
//                     const Text("Specifications:",
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold)),
//                     ...equipment.specs.map((spec) => Text("• $spec",
//                         style: const TextStyle(fontSize: 14))),
//                     const SizedBox(height: 20),
                   
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () => _selectDate(context, true),
//                           child: Text(startDate == null
//                               ? "Start Date"
//                               : DateFormat('yyyy-MM-dd').format(startDate!)),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => _selectDate(context, false),
//                           child: Text(endDate == null
//                               ? "End Date"
//                               : DateFormat('yyyy-MM-dd').format(endDate!)),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
                  
//                     Row(
//                       children: [
//                         ElevatedButton(
//                           onPressed: () async {
//                             final TimeOfDay? picked = await showTimePicker(
//                               context: context,
//                               initialTime: TimeOfDay.now(),
//                             );
//                             if (picked != null) {
//                               setState(() {
//                                 pickupTime = picked.format(context);
//                               });
//                             }
//                           },
//                           child: Text(
//                             pickupTime == null ? "Select Pickup Time" : pickupTime!,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
                 
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () {
//                             OrdersManager.addOrder(equipment);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('${equipment.title} added to Orders'),
//                                 duration: const Duration(seconds: 1),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF8A005D),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 30, vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           child: const Text(
//                             "Rent Now",
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                         ),
                    
//                         TextButton(
//                           onPressed: () {
                           
//                             const double fixedLat = 31.9539;
//                             const double fixedLng = 35.9106;

//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const MapScreen(
//                                   initialPosition: LatLng(fixedLat, fixedLng),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             "See Location",
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'Orders.dart';
import 'EquipmentItem.dart';
import 'Favourite.dart';
import 'MapPage.dart';

class EquipmentDetailPage extends StatefulWidget {
  static const routeName = '/equipment-detail';
  const EquipmentDetailPage({super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  bool isFavoritePressed = false;
  int _currentPage = 0;

  DateTime? startDate;
  DateTime? endDate;
  String? pickupTime;

  int likesCount = 0;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipment =
        ModalRoute.of(context)?.settings.arguments as EquipmentItem?;

    if (equipment == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No equipment data provided!",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
    }

    isFavoritePressed = FavouriteManager.favouriteItems.contains(equipment);
    likesCount = likesCount == 0 ? equipment.likes : likesCount;

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
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 10 : 8,
                            height: _currentPage == index ? 10 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? const Color(0xFF8A005D)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
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
                            isFavoritePressed = !isFavoritePressed;
                            if (isFavoritePressed) {
                              FavouriteManager.add(equipment);
                              likesCount++;
                            } else {
                              FavouriteManager.remove(equipment);
                              if (likesCount > 0) likesCount--;
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
                  ],
                ),
              ),

              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.title,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),

                    const SizedBox(height: 10),

                   
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 22),
                        const SizedBox(width: 4),
                        Text("${equipment.rating}",
                            style: const TextStyle(fontSize: 16)),
                        Text(" (${equipment.reviews} reviews)",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        const SizedBox(width: 16),
                        const Icon(Icons.thumb_up, color: Colors.green, size: 20),
                        Text(" $likesCount",
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 16),
                        const Icon(Icons.shopping_bag,
                            color: Colors.blue, size: 20),
                        Text(" ${equipment.rentedCount}",
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Rental Price: \$${equipment.pricePerDay * 7}/Week",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A005D)),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      equipment.description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 14),

                    Text("Release Year: ${equipment.releaseYear}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),

                    const SizedBox(height: 14),

                    const Text("Specifications:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    ...equipment.specs.map(
                      (spec) =>
                          Text("• $spec", style: const TextStyle(fontSize: 14)),
                    ),

                    const SizedBox(height: 20),

                   
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectDate(context, true),
                          child: Text(startDate == null
                              ? "Start Date"
                              : DateFormat('yyyy-MM-dd').format(startDate!)),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectDate(context, false),
                          child: Text(endDate == null
                              ? "End Date"
                              : DateFormat('yyyy-MM-dd').format(endDate!)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

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
                      child: Text(
                        pickupTime == null
                            ? "Select Pickup Time"
                            : pickupTime!,
                      ),
                    ),

                    const SizedBox(height: 20),

                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       
                        ElevatedButton(
                          onPressed: () {
                            OrdersManager.addOrder(equipment);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${equipment.title} added to Orders'),
                                duration: const Duration(seconds: 1),
                              ),
                            );

                    
                            Future.delayed(
                                const Duration(milliseconds: 300), () {
                              Navigator.pushNamed(context, '/orders');
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A005D),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Rent Now",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            const double fixedLat = 31.9539;
                            const double fixedLng = 35.9106;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapScreen(
                                  initialPosition: LatLng(fixedLat, fixedLng),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "See Location",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

