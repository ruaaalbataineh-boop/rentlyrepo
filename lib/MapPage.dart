
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

const String kGoogleApiKey = "YOUR_REAL_GOOGLE_API_KEY_HERE";

class MapScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapScreen({super.key, required this.initialPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;

  
  final Set<Marker> _markers = {};

  
  final LatLng ownerLocation = const LatLng(32.55, 35.85);

  final List<LatLng> polylineCoordinates = [];
  final Set<Polyline> polylines = {};

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = "Location services are disabled. Please enable GPS.";
          _loading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = "Location permission denied.";
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              "Location permission permanently denied. Enable permissions from settings.";
          _loading = false;
        });
        return;
      }

      await _getLocation();
    } catch (e) {
      setState(() {
        _errorMessage = "Error obtaining location: $e";
        _loading = false;
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _addMarkers();
        _loading = false;
      });

      
      await _getPolyline();

      if (mapController != null && currentLocation != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation!, 14),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to get location: $e";
        _loading = false;
      });
    }
  }

 
  void _addMarkers() {
    _markers.clear();

    if (currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("renter"),
          position: currentLocation!,
          infoWindow: const InfoWindow(title: "Renter (You)"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId("owner"),
        position: ownerLocation,
        infoWindow: const InfoWindow(title: "Owner Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getPolyline() async {
    if (currentLocation == null) return;

    try {
      final PolylinePoints polylinePoints = PolylinePoints(
        apiKey: "AIzaSyCnSc-MLAUUyP5kxdcJ7TVk1TyyL-Rqt7s",
      );

      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            currentLocation!.latitude,
            currentLocation!.longitude,
          ),
          destination: PointLatLng(
            ownerLocation.latitude,
            ownerLocation.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(
            LatLng(point.latitude, point.longitude),
          );
        }

        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("Polyline error: $e");
    }
  }

 
  @override
  Widget build(BuildContext context) {
    if (_loading && currentLocation == null && _errorMessage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Rently Map")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && currentLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Rently Map")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    _determinePosition();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final LatLng initialCamPos = currentLocation ?? widget.initialPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rently Map"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialCamPos,
          zoom: 14,
        ),
        markers: _markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
          if (currentLocation != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(currentLocation!, 14),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _loading = true;
            _errorMessage = null;
          });
          _determinePosition();
        },
        label: const Text("Refresh Location"),
        icon: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}


