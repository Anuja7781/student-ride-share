import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class RideTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String rideId;
  final int otp;

  const RideTrackingScreen({
    super.key,
    required this.rideData,
    required this.rideId,
    required this.otp,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  LatLng? userLocation;
  LatLng? driverLocation;

  List<LatLng> routePoints = [];
  final MapController mapController = MapController();

  StreamSubscription? driverStream;

  final String apiKey = "YOUR_OPENROUTESERVICE_KEY_HERE";

  @override
  void initState() {
    super.initState();
    getUserLocation();
    listenDriverLocation();
  }

  Future<void> getUserLocation() async {
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLocation = LatLng(position.latitude, position.longitude);
    setState(() {});

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      userLocation = LatLng(position.latitude, position.longitude);
      setState(() {});
    });
  }

  Future<void> sendSOSWithLocation(String number) async {
    if (number.isEmpty) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final lat = position.latitude;
    final lng = position.longitude;

    final link =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    final message =
        "SOS ALERT\nNeed help urgently\nLocation:\n$link";

    final Uri uri =
        Uri.parse("sms:$number?body=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void listenDriverLocation() {
    driverStream = FirebaseFirestore.instance
        .collection("rides")
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      final lat = (data["lat"] as num?)?.toDouble();
      final lng = (data["lng"] as num?)?.toDouble();

      if (lat == null || lng == null) return;

      driverLocation = LatLng(lat, lng);
      setState(() {});

      fetchRoute();
    });
  }

  Future<void> fetchRoute() async {
    if (userLocation == null || driverLocation == null) return;

    final url = Uri.parse(
        "https://api.openrouteservice.org/v2/directions/driving-car");

    final body = {
      "coordinates": [
        [driverLocation!.longitude, driverLocation!.latitude],
        [userLocation!.longitude, userLocation!.latitude]
      ]
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": apiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final encoded = data["routes"]?[0]?["geometry"];
      if (encoded == null) return;

      routePoints = decodePolyline(encoded);
      setState(() {});
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  Future<void> sendSOS() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("sos_alerts").add({
      "userId": uid,
      "rideId": widget.rideId,
      "time": FieldValue.serverTimestamp(),
      "message": "Emergency SOS triggered",
    });
  }

  @override
  void dispose() {
    driverStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final driver = widget.rideData["driverName"] ?? "Driver";
    final vehicle = widget.rideData["vehicleNumber"] ?? "Not Provided";

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: driverLocation ?? userLocation!,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.student_ride_app',
              ),
              MarkerLayer(
                markers: [
                  if (driverLocation != null)
                    Marker(
                      point: driverLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 35,
                      ),
                    ),
                  Marker(
                    point: userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 35,
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$driver is on the way"),
                  Text("🚗 $vehicle"),
                  Text("OTP: ${widget.otp}"),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 140,
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                sendSOS();
                sendSOSWithLocation(widget.rideData["phone"] ?? "");
              },
              child: const Icon(Icons.shield),
            ),
          ),
        ],
      ),
    );
  }
}