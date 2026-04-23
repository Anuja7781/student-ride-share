import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Created Rides"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rides")
            .where("driverId", isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No rides created"));
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {

              var ride = rides[index];
              var rideData = ride.data() as Map<String, dynamic>;

              String status = rideData["status"] ?? "active";

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🚗 ROUTE
                      Text(
                        "${rideData["source"]} → ${rideData["destination"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text("Seats left: ${rideData["availableSeats"]}"),
                      Text("Status: $status"),

                      const SizedBox(height: 10),

                      // 👥 BOOKINGS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("bookings")
                            .where("rideId", isEqualTo: ride.id)
                            .snapshots(),
                        builder: (context, bookingSnapshot) {

                          if (!bookingSnapshot.hasData) {
                            return const Text("Loading bookings...");
                          }

                          var bookings = bookingSnapshot.data!.docs;

                          if (bookings.isEmpty) {
                            return const Text("No bookings yet");
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: bookings.map((b) {

                              var data = b.data() as Map<String, dynamic>;

                              return Text(
                                "👤 ${data["userName"]} (${data["status"]})",
                              );

                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 🔘 ACTION BUTTONS (only if active)
                      if (status == "active")
                        Row(
                          children: [

                            // ✅ COMPLETE RIDE
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("rides")
                                    .doc(ride.id)
                                    .update({
                                  "status": "completed",
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Ride Completed")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Complete"),
                            ),

                            const SizedBox(width: 10),

                            // ❌ CANCEL RIDE
                            ElevatedButton(
                              onPressed: () async {

                                // update ride
                                await FirebaseFirestore.instance
                                    .collection("rides")
                                    .doc(ride.id)
                                    .update({
                                  "status": "cancelled",
                                });

                                // update all bookings
                                var bookings = await FirebaseFirestore.instance
                                    .collection("bookings")
                                    .where("rideId", isEqualTo: ride.id)
                                    .get();

                                for (var doc in bookings.docs) {
                                  await doc.reference.update({
                                    "status": "cancelled",
                                  });
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Ride Cancelled")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Cancel"),
                            ),
                          ],
                        ),


                      if (status != "active")
                        Text(
                          status == "completed"
                              ? "✅ Ride Completed"
                              : "❌ Ride Cancelled",
                          style: TextStyle(
                            color: status == "completed"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}