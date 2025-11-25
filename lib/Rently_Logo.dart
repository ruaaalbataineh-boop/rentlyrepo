import 'dart:async';
import 'package:flutter/material.dart';

class RentlyApp extends StatefulWidget {
  const RentlyApp({super.key});

  @override
  State<RentlyApp> createState() => _RentlyAppState();
}

class _RentlyAppState extends State<RentlyApp> {
  @override
  void initState() {
    super.initState();

    
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/create');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.diamond, size: 80, color: Colors.white),
              SizedBox(height: 12),
              Text(
                "Rently",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:p2/AddItemPage%20.dart';


// class RentlyApp extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<RentlyApp> {
//   List<Map<String, dynamic>> items = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Rently Items"),
//         backgroundColor: Colors.deepPurple,
//       ),

//       body: items.isEmpty
//           ? Center(
//               child: Text(
//                 "No items yet.\nPress + to add one!",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 20, color: Colors.grey),
//               ),
//             )
//           : ListView.builder(
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 return Card(
//                   margin: EdgeInsets.all(12),
//                   child: ListTile(
//                     leading: items[index]["image"] == ""
//                         ? Icon(Icons.image_not_supported)
//                         : Image.file(File(items[index]["image"])),
//                     title: Text(items[index]["name"]),
//                     subtitle: Text(
//                       "${items[index]["desc"]}\nCategory: ${items[index]["category"]}",
//                     ),
//                     trailing: Text("${items[index]["price"]} JD"),
//                   ),
//                 );
//               },
//             ),

//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.deepPurple,
//         child: Icon(Icons.add),
//         onPressed: () async {
//           final newItem = await Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddItemPage()),
//           );

//           if (newItem != null) {
//             setState(() {
//               items.add(newItem);
//             });
//           }
//         },
//       ),
//     );
//   }
// }