import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final double lat;
  final double lng;

  const MapScreen({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        backgroundColor: Colors.blue,
      ),

      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 15,
        ),
        children: [

          // 🗺️ FIXED TILE LAYER (VERY IMPORTANT)
          TileLayer(
            urlTemplate:
            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName:
            'com.example.student_ride_app', // ⭐ FIX FOR 403 ERROR
          ),

          // 📍 DRIVER MARKER
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: Column(
                  children: const [
                    Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 30,
                    ),
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}