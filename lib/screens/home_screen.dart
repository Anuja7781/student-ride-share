import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_ride_screen.dart';
import 'profile_screen.dart';

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
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Find Ride handled by Person A"),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bookings screen coming soon"),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    
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
                        children: const [

                          Text(
                            "Dashboard Overview",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text("📊 Your Activity (Static for now)"),
                          SizedBox(height: 5),
                          Text("🚗 Rides Created: 0"),
                          Text("📍 Active Rides: 0"),
                          Text("📅 Bookings: 0"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                   
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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