import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {

  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  final timeController = TextEditingController();
  final seatsController = TextEditingController();
  final fareController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleController = TextEditingController();

  bool isLoading = false;
  bool isGirlsOnly = false;

  // ⭐ convert place → coordinates
  Future<Map<String, double>> getCoordinates(String place) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$place&format=json");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isNotEmpty) {
        return {
          "lat": double.parse(data[0]["lat"]),
          "lng": double.parse(data[0]["lon"]),
        };
      }
    }

    throw Exception("Location not found");
  }

  Future<void> createRide() async {

    if (
    sourceController.text.isEmpty ||
        destinationController.text.isEmpty ||
        timeController.text.isEmpty ||
        seatsController.text.isEmpty ||
        fareController.text.isEmpty ||
        phoneController.text.isEmpty ||
        vehicleController.text.isEmpty
    ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // ⭐ get real coordinates
      final sourceCoords =
      await getCoordinates(sourceController.text.trim());

      final destCoords =
      await getCoordinates(destinationController.text.trim());

      await FirebaseFirestore.instance.collection("rides").add({
        "source": sourceController.text.trim(),
        "destination": destinationController.text.trim(),
        "time": timeController.text.trim(),

        "seats": int.parse(seatsController.text),
        "availableSeats": int.parse(seatsController.text),

        "fare": int.parse(fareController.text),

        "driverId": uid,
        "driverName":
        FirebaseAuth.instance.currentUser?.email ?? "Student",

        "phone": phoneController.text.trim(),
        "vehicleNumber": vehicleController.text.trim(),

        "isGirlsOnly": isGirlsOnly,
        "status": "active",

        // ⭐ REAL LOCATIONS
        "lat": sourceCoords["lat"],
        "lng": sourceCoords["lng"],
        "destLat": destCoords["lat"],
        "destLng": destCoords["lng"],

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Created Successfully 🚗")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    sourceController.dispose();
    destinationController.dispose();
    timeController.dispose();
    seatsController.dispose();
    fareController.dispose();
    phoneController.dispose();
    vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Ride"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.blue.shade50,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            buildField(sourceController, "From"),
            buildField(destinationController, "To"),
            buildField(timeController, "Time"),
            buildField(seatsController, "Seats", isNumber: true),
            buildField(fareController, "Fare", isNumber: true),
            buildField(phoneController, "Phone", isNumber: true),
            buildField(vehicleController, "Vehicle Number"),

            SwitchListTile(
              title: const Text("Girls Only Ride"),
              value: isGirlsOnly,
              onChanged: (value) {
                setState(() {
                  isGirlsOnly = value;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : createRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Ride"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}