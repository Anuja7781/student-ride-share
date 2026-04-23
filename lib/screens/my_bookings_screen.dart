import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_tracking_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: Colors.blue,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("userId", isEqualTo: uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              var bookingDoc = bookings[index];
              var booking = bookingDoc.data() as Map<String, dynamic>;

              String rideId = booking["rideId"];
              String status = booking["status"] ?? "active";
              var otp = booking["otp"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("rides")
                    .doc(rideId)
                    .get(),

                builder: (context, rideSnapshot) {

                  if (!rideSnapshot.hasData) {
                    return const SizedBox();
                  }

                  var rideDoc = rideSnapshot.data!;

                  if (!rideDoc.exists) {
                    return const ListTile(
                      title: Text("Ride not available"),
                    );
                  }

                  var data = rideDoc.data() as Map<String, dynamic>;

                  String source = data["source"] ?? "";
                  String destination = data["destination"] ?? "";
                  int fare = data["fare"] ?? 0;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 🚗 ROUTE
                          Text(
                            "$source → $destination",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // 💰 + OTP
                          Text("₹$fare • OTP: ${otp ?? "----"}"),

                          const SizedBox(height: 5),

                          // 📊 STATUS
                          Text(
                            "Status: $status",
                            style: TextStyle(
                              color: status == "active"
                                  ? Colors.green
                                  : status == "completed"
                                  ? Colors.blue
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 🔘 ACTION BUTTONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              // 📍 TRACK BUTTON
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RideTrackingScreen(
                                        rideData: data,
                                        otp: otp ?? 0,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Track"),
                              ),

                              // ❌ CANCEL BUTTON (only if active)
                              ElevatedButton(
                                onPressed: status == "active"
                                    ? () async {
                                  await FirebaseFirestore.instance
                                      .collection("bookings")
                                      .doc(bookingDoc.id)
                                      .update({
                                    "status": "cancelled",
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Booking Cancelled"),
                                    ),
                                  );
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}