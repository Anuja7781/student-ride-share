import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicTransportScreen extends StatefulWidget {
  const PublicTransportScreen({super.key});

  @override
  State<PublicTransportScreen> createState() => _PublicTransportScreenState();
}

class _PublicTransportScreenState extends State<PublicTransportScreen> {
  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  final timeController = TextEditingController();

  String transportType = "Bus";
  bool isLoading = false;

  @override
  void dispose() {
    sourceController.dispose();
    destinationController.dispose();
    timeController.dispose();
    super.dispose();
  }

  Future<void> createTrip() async {
    if (sourceController.text.isEmpty ||
        destinationController.text.isEmpty ||
        timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      await FirebaseFirestore.instance.collection("public_trips").add({
        "source": sourceController.text.trim(),
        "destination": destinationController.text.trim(),
        "time": timeController.text.trim(),
        "transportType": transportType,
        "userId": uid,
        "userName": userDoc["name"] ?? "User",
        "participants": [],
        "createdAt": FieldValue.serverTimestamp(), // ✅ FIXED
      });

      sourceController.clear();
      destinationController.clear();
      timeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip Created 🚍")),
      );
    } catch (e) {
  debugPrint("CREATE TRIP ERROR: $e");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $e")),
  );
}

    setState(() => isLoading = false);
  }

  Future<void> joinTrip(String tripId, List participants) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    if (participants.contains(uid)) return;

    await FirebaseFirestore.instance
        .collection("public_trips")
        .doc(tripId)
        .update({
      "participants": FieldValue.arrayUnion([uid])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Together 🚌"),
        backgroundColor: Colors.teal,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [

              // 📦 CREATE TRIP CARD
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: Column(
                  children: [

                    const Text(
                      "Create Travel Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    buildField(sourceController, "From"),
                    buildField(destinationController, "To"),
                    buildField(timeController, "Time"),

                    const SizedBox(height: 10),

                    DropdownButton<String>(
                      value: transportType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: "Bus", child: Text("Bus")),
                        DropdownMenuItem(value: "Auto", child: Text("Auto")),
                        DropdownMenuItem(value: "Train", child: Text("Train")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          transportType = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : createTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Create Trip"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Available Trips",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // 🚍 TRIPS LIST
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("public_trips")
                    .snapshots(), // ✅ FIXED (removed orderBy)

                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No trips available");
                  }

                  var trips = snapshot.data!.docs;

                  return Column(
                    children: trips.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      List participants = data["participants"] ?? [];

                      return Container(
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

                            Text("🚌 ${data["transportType"] ?? ""}"),
                            Text("⏰ ${data["time"] ?? ""}"),
                            Text("👤 ${data["userName"] ?? ""}"),
                            Text("👥 Joined: ${participants.length}"),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    joinTrip(doc.id, participants),
                                child: const Text("Join Trip"),
                              ),
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

  Widget buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}