import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapScreen({super.key, required this.initialPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    _addEquipmentMarker();
    await _getCurrentLocation();
  }

  void _addEquipmentMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId("equipment"),
        position: widget.initialPosition,
        infoWindow: const InfoWindow(title: "Equipment Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    // ignore: empty_catches
    } catch (e) {
     
    }

    setState(() {
      _isLoading = false;
    });

   
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(widget.initialPosition, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: widget.initialPosition, zoom: 14),
              myLocationEnabled: true,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:permission_handler/permission_handler.dart';

// class MapScreen extends StatefulWidget {
//   final LatLng initialPosition;
//   const MapScreen({super.key, required this.initialPosition});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   late GoogleMapController _mapController;
//   Position? _currentPosition;
//   Set<Marker> _markers = {};
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initMap();
//   }

//
//   Future<void> _initMap() async {
//     await _checkLocationPermission();
//     _addEquipmentMarker();
//     await _loadCurrentLocation();
//     await _loadAllItems();
//   }

//   
//  Future<bool> _checkLocationPermission() async {
//   
//   if (!await Geolocator.isLocationServiceEnabled()) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Please enable GPS first')),
//     );
//     return false;
//   }

//   
//   var status = await Permission.location.status;
//   if (!status.isGranted) {
//     status = await Permission.location.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location permission denied')),
//       );
//       return false;
//     }
//   }

//   return true; 
// }

//   
//   void _addEquipmentMarker() {
//     _markers.add(
//       Marker(
//         markerId: const MarkerId("equipment"),
//         position: widget.initialPosition,
//         infoWindow: const InfoWindow(title: "Equipment Location"),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ),
//     );
//   }

//   // 
//   Future<void> _loadCurrentLocation() async {
//     setState(() => _isLoading = true);

//     try {
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);

//       setState(() {
//         _currentPosition = position;
//         _markers.add(
//           Marker(
//             markerId: const MarkerId("me"),
//             position: LatLng(position.latitude, position.longitude),
//             infoWindow: const InfoWindow(title: "You are here"),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           ),
//         );
//       });

//       
//       _mapController.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(position.latitude, position.longitude),
//           14,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error getting location: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   
//   Future<void> _loadAllItems() async {
//     QuerySnapshot snap =
//         await FirebaseFirestore.instance.collection('items').get();

//     Set<Marker> loadedMarkers = {};

//     for (var doc in snap.docs) {
//       var data = doc.data() as Map<String, dynamic>;
//       if (data['lat'] != null && data['lng'] != null) {
//         loadedMarkers.add(
//           Marker(
//             markerId: MarkerId(doc.id),
//             position: LatLng(data['lat'], data['lng']),
//             infoWindow: InfoWindow(title: data['name'] ?? 'Item'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//           ),
//         );
//       }
//     }

//     
//     loadedMarkers.add(
//       Marker(
//         markerId: const MarkerId("equipment"),
//         position: widget.initialPosition,
//         infoWindow: const InfoWindow(title: "Equipment Location"),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ),
//     );

//     
//     if (_currentPosition != null) {
//       loadedMarkers.add(
//         Marker(
//           markerId: const MarkerId("me"),
//           position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//           infoWindow: const InfoWindow(title: "You are here"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         ),
//       );
//     }

//     setState(() => _markers = loadedMarkers);
//   }

//   
//   Future<void> _saveMyLocation() async {
//     if (_currentPosition == null) return;

//     await FirebaseFirestore.instance.collection('users_locations').add({
//       'lat': _currentPosition!.latitude,
//       'lng': _currentPosition!.longitude,
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Location saved to Firebase ')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Rently - Map & Location"),
//         backgroundColor: Colors.blueAccent,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadAllItems,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: widget.initialPosition,
//                 zoom: 12,
//               ),
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//               zoomControlsEnabled: true,
//               onMapCreated: (controller) => _mapController = controller,
//               markers: _markers,
//             ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           FloatingActionButton.extended(
//             onPressed: _loadCurrentLocation,
//             label: const Text("Get My Location"),
//             icon: const Icon(Icons.my_location),
//           ),
//           const SizedBox(height: 10),
//           FloatingActionButton.extended(
//             onPressed: _saveMyLocation,
//             label: const Text("Save Location"),
//             icon: const Icon(Icons.cloud_upload),
//           ),
//         ],
//       ),
//     );
//   }
// }


