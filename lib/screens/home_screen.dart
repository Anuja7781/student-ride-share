import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_ride_screen.dart';
import 'profile_screen.dart';
import 'find_ride_screen.dart';
import 'my_bookings_screen.dart';
import 'my_rides_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String userName = "User";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      setState(() {
        userName = userDoc["name"] ?? "User";
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    String currentUserId = FirebaseAuth.instance.currentUser!.uid; // ⭐ ADDED

    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Campus Connect"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Hello, $userName 👋",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // 🔘 BUTTONS
              Row(
                children: [

                  Expanded(
                    child: buildSmallButton(
                      "Find",
                      Icons.search,
                      const Color(0xFF7C4DFF),
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FindRideScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: buildSmallButton(
                      "Create",
                      Icons.add,
                      Colors.green,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateRideScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: buildSmallButton(
                      "Bookings",
                      Icons.book,
                      Colors.orange,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyBookingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: buildSmallButton(
                      "My Rides",
                      Icons.directions_car,
                      Colors.blue,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyRidesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 📊 DASHBOARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dashboard Overview",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("📊 Your Activity"),
                    Text("🚗 Rides Created: Coming soon"),
                    Text("📅 Bookings: Coming soon"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🚗 RECENT RIDES
              const Text(
                "🚗 Recent Rides",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("rides")
                    .orderBy("createdAt", descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var rides = snapshot.data!.docs;

                  // 🔥 APPLY FILTER HERE
                  rides = rides.where((doc) {

                    var data = doc.data() as Map<String, dynamic>;

                    // ❌ hide own rides
                    if (data["driverId"] == currentUserId) {
                      return false;
                    }

                    // ❌ hide full rides
                    if ((data["availableSeats"] ?? 0) <= 0) {
                      return false;
                    }

                    return true;

                  }).toList();

                  if (rides.isEmpty) {
                    return const Text("No rides available");
                  }

                  return Column(
                    children: rides.map((doc) {

                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              "${data["source"]} → ${data["destination"]}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 5),

                            Text("💰 ₹${data["fare"]}"),

                            const SizedBox(height: 5),

                            Text(
                              data["isGirlsOnly"] == true
                                  ? "🏷️ Girls Only"
                                  : "🏷️ All Students",
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSmallButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}