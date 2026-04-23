import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ride_details_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {

  bool girlsOnly = false;

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Ride"),
        backgroundColor: const Color(0xFF243B6B),
      ),

      body: Column(
        children: [

          // 🔍 SEARCH BOX
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [

                TextField(
                  controller: fromController,
                  decoration: const InputDecoration(
                    labelText: "From",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: "To",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text("Search"),
                  ),
                ),
              ],
            ),
          ),

          // 🔘 GIRLS ONLY FILTER
          SwitchListTile(
            title: const Text("Girls Only"),
            value: girlsOnly,
            onChanged: (value) {
              setState(() {
                girlsOnly = value;
              });
            },
          ),

          // 📄 RIDES LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("rides")
                  .where("status", isEqualTo: "active")
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var rides = snapshot.data!.docs;

                // 🔥 FILTER LOGIC
                rides = rides.where((doc) {

                  var data = doc.data() as Map<String, dynamic>;

                  // ❌ Hide own rides
                  if (data["driverId"] == currentUserId) {
                    return false;
                  }

                  // ❌ Hide full rides
                  if ((data["availableSeats"] ?? 0) <= 0) {
                    return false;
                  }

                  // 🔍 From match
                  bool fromMatch = fromController.text.isEmpty ||
                      (data["source"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(fromController.text.toLowerCase());

                  // 🔍 To match
                  bool toMatch = toController.text.isEmpty ||
                      (data["destination"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(toController.text.toLowerCase());

                  // 👩 Girls only filter
                  bool girlsMatch =
                      !girlsOnly || data["isGirlsOnly"] == true;

                  return fromMatch && toMatch && girlsMatch;

                }).toList();

                if (rides.isEmpty) {
                  return const Center(child: Text("No rides found"));
                }

                return ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) {

                    var data = rides[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          "${data["source"]} → ${data["destination"]}",
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("₹${data["fare"]}"),
                            Text("Time: ${data["time"] ?? ""}"),
                          ],
                        ),

                        trailing: Text(
                          "${data["availableSeats"]} seats",
                          style: const TextStyle(color: Colors.green),
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RideDetailsScreen(
                                rideId: rides[index].id,
                                rideData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}