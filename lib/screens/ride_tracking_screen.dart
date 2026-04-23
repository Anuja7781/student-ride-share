import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RideTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final int otp;

  const RideTrackingScreen({
    super.key,
    required this.rideData,
    required this.otp,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {

  List<LatLng> routePoints = [];
  final MapController mapController = MapController();

  // ✅ USE THIS TYPE OF KEY (NOT eyJ...)
  final String apiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjFmNmU1MTc2OGFlYzQ0ODJiMmNiZmE5ZTg3NDJkMWM0IiwiaCI6Im11cm11cjY0In0=";

  @override
  void initState() {
    super.initState();
    fetchRoute();
  }

  // ✅ MANUAL POLYLINE DECODE (NO PACKAGE NEEDED)
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  Future<void> fetchRoute() async {

    double driverLat = widget.rideData["lat"] ?? 18.5204;
    double driverLng = widget.rideData["lng"] ?? 73.8567;

    double userLat = 18.5310;
    double userLng = 73.8440;

    final url = Uri.parse(
        "https://api.openrouteservice.org/v2/directions/driving-car");

    final body = {
      "coordinates": [
        [driverLng, driverLat],
        [userLng, userLat]
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String encoded = data["routes"][0]["geometry"];

        List<LatLng> points = decodePolyline(encoded);

        setState(() {
          routePoints = points;
        });

        if (points.isNotEmpty) {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(40),
            ),
          );
        }

      } else {
        print("❌ API ERROR: ${response.body}");
      }

    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    double driverLat = widget.rideData["lat"] ?? 18.5204;
    double driverLng = widget.rideData["lng"] ?? 73.8567;

    double userLat = 18.5310;
    double userLng = 73.8440;

    String driver = widget.rideData["driverName"] ?? "Driver";
    String vehicle = widget.rideData["vehicleNumber"]?.toString() ?? "Not Provided";

    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(driverLat, driverLng),
              initialZoom: 14.5,
            ),
            children: [

              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName:
                'com.example.student_ride_app',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(driverLat, driverLng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.directions_car,
                        color: Colors.blue, size: 35),
                  ),
                  Marker(
                    point: LatLng(userLat, userLng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 35),
                  ),
                ],
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 40,
            left: 15,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text("Driver is on the way",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 5),

                  Text("$driver will reach in 5 minutes"),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("🚗 $vehicle"),
                          Text("🔐 OTP: ${widget.otp}"),
                        ],
                      ),

                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Calling driver...")),
                          );
                        },
                        child: const Text("Call"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}