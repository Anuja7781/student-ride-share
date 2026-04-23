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

  // ⭐ CHECK IF USER ALREADY BOOKED
  Future<void> checkBooking() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var query = await FirebaseFirestore.instance
        .collection("bookings")
        .where("rideId", isEqualTo: widget.rideId)
        .where("userId", isEqualTo: uid)
        .get();

    setState(() {
      isBooked = query.docs.isNotEmpty;
      isLoading = false;
    });
  }

  Future<void> bookRide(BuildContext context) async {
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

    String uid = FirebaseAuth.instance.currentUser!.uid;

    int otp = 1000 + Random().nextInt(9000);

    try {
      // update seats
      await FirebaseFirestore.instance
          .collection("rides")
          .doc(widget.rideId)
          .update({
        "availableSeats": seats - 1,
      });

      // create booking
      await FirebaseFirestore.instance.collection("bookings").add({
        "rideId": widget.rideId,
        "userId": uid,
        "userName": FirebaseAuth.instance.currentUser?.email ?? "Student",
        "otp": otp,
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Booked 🚗")),
      );

      setState(() {
        isBooked = true;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    String driverName = widget.rideData["driverName"] ?? "Student";
    String phone = widget.rideData["phone"] ?? "Not available";
    String vehicle = widget.rideData["vehicleNumber"] ?? "Not available";
    int seats = widget.rideData["availableSeats"] ?? 0;

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

            // 📍 ROUTE
            Text(
              "${widget.rideData["source"]} → ${widget.rideData["destination"]}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("💰 Fare: ₹${widget.rideData["fare"]}"),
            Text("🪑 Seats Left: $seats"),
            Text("🕒 Time: ${widget.rideData["time"] ?? ""}"),

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

            // 🚗 BOOK BUTTON (SMART)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isBooked || seats <= 0)
                    ? null
                    : () => bookRide(context),
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