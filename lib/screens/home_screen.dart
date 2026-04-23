import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_ride_screen.dart';
import 'profile_screen.dart';
import 'public_transport_screen.dart';

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
        userName =
            (userDoc.data() as Map<String, dynamic>?)?["name"] ?? "User";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> getRecentRides() {
    return FirebaseFirestore.instance
        .collection("rides")
        .orderBy("createdAt", descending: true)
        .limit(5)
        .snapshots();
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

                    Row(
                      children: [
                        Expanded(
                          child: buildSmallButton(
                            "Find",
                            Icons.search,
                            const Color(0xFF7C4DFF),
                            () {},
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
                            () {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PublicTransportScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions_bus),
                        label: const Text("Travel Together",
                        style: TextStyle(
                                          color: Colors.white,
                                          ),
                                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "📊 Your Activity",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 10),

                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("rides")
                                .where("driverId",
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int count = snapshot.data?.docs.length ?? 0;
                              return Text("🚗 Rides Created: $count");
                            },
                          ),

                          const SizedBox(height: 6),

                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("rides")
                                .where("driverId",
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int activeCount = 0;

                              if (snapshot.hasData) {
                                activeCount =
                                    snapshot.data!.docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return (data["availableSeats"] ?? 0) > 0;
                                }).length;
                              }

                              return Text(
                                  "📍 Active Rides: $activeCount");
                            },
                          ),

                          const SizedBox(height: 6),

                          const Text("📅 Bookings: (coming soon)"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🛡️ SAFETY
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
                          Text(
                            "🛡️ Safety Features",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("✔ Verified Student Platform"),
                          Text("✔ Girls-only Ride Support"),
                          Text("✔ SOS Emergency Button"),
                          Text("✔ Live Tracking (Upcoming)"),
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
                      stream: getRecentRides(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Text("No rides available");
                        }

                        var rides = snapshot.data!.docs;

                        return Column(
                          children: rides.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;

                            return Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${data["source"] ?? ""} → ${data["destination"] ?? ""}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text("💰 ₹${data["fare"] ?? 0}"),
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