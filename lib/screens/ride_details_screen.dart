import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_tracking_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  bool isBooked = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkBooking();
  }

  // ✅ SAFE BOOKING CHECK (FIXED BUFFER ISSUE)
  Future<void> checkBooking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      var query = await FirebaseFirestore.instance
          .collection("bookings")
          .where("rideId", isEqualTo: widget.rideId)
          .where("userId", isEqualTo: user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        isBooked = query.docs.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("checkBooking error: $e");

      if (!mounted) return;

      setState(() {
        isBooked = false;
        isLoading = false; // 🔥 IMPORTANT FIX (prevents buffering)
      });
    }
  }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    int seats = widget.rideData["availableSeats"] ?? 0;

    if (seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Full ❌")),
      );
      return;
    }

    if (isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already booked")),
      );
      return;
    }

    int otp = 1000 + Random().nextInt(9000);

    try {
      // 🔥 update seats safely
      await FirebaseFirestore.instance
          .collection("rides")
          .doc(widget.rideId)
          .update({
        "availableSeats": seats - 1,
      });

      // 🔥 create booking
      await FirebaseFirestore.instance.collection("bookings").add({
        "rideId": widget.rideId,
        "userId": user.uid,
        "userName": user.email ?? "Student",
        "otp": otp,
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isBooked = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Booked 🚗")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideTrackingScreen(
            rideData: widget.rideData,
            otp: otp,
          ),
        ),
      );
    } catch (e) {
      debugPrint("booking error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.rideData;

    String driverName = data["driverName"] ?? "Student";
    String phone = data["phone"] ?? "Not available";
    String vehicle = data["vehicleNumber"] ?? "Not available";
    int seats = data["availableSeats"] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Details"),
        backgroundColor: Colors.blue,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "${data["source"]} → ${data["destination"]}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("💰 Fare: ₹${data["fare"]}"),
                  Text("🪑 Seats Left: $seats"),
                  Text("🕒 Time: ${data["time"] ?? ""}"),

                  const SizedBox(height: 15),

                  Text("👤 Driver: $driverName"),
                  Text("📞 Phone: $phone"),
                  Text("🚗 Vehicle: $vehicle"),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling $phone")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text("Call Driver"),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (isBooked || seats <= 0)
                          ? null
                          : bookRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked
                            ? Colors.grey
                            : seats <= 0
                                ? Colors.red
                                : Colors.green,
                      ),
                      child: Text(
                        isBooked
                            ? "Already Booked"
                            : seats <= 0
                                ? "Ride Full"
                                : "Book Ride",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}