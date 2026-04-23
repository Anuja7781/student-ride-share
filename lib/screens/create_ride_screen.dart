import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool isLoading = false;
  bool isGirlsOnly = false; // 

  Future<void> createRide() async {

    if (
      sourceController.text.isEmpty ||
      destinationController.text.isEmpty ||
      timeController.text.isEmpty ||
      seatsController.text.isEmpty ||
      fareController.text.isEmpty
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

      await FirebaseFirestore.instance.collection("rides").add({
        "source": sourceController.text.trim(),
        "destination": destinationController.text.trim(),
        "time": timeController.text.trim(),

        "seats": int.tryParse(seatsController.text.trim()) ?? 0,
        "availableSeats": int.tryParse(seatsController.text.trim()) ?? 0,

        "fare": int.tryParse(fareController.text.trim()) ?? 0,

        "driverId": uid,

        
        "driverName": FirebaseAuth.instance.currentUser?.email ?? "Student",
        "isGirlsOnly": isGirlsOnly,

        
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Created Successfully 🚗")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create ride")),
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
            buildField(timeController, "Time (e.g. 5:30 PM)"),
            buildField(seatsController, "Total Seats", isNumber: true),
            buildField(fareController, "Fare per seat", isNumber: true),

            const SizedBox(height: 10),

            
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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : createRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Ride",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
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