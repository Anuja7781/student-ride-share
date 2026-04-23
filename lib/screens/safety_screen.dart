import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      setState(() {
        userData = doc.data() as Map<String, dynamic>;
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
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF243B6B),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("No user data found"))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF7C4DFF),
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        userData!["name"] ?? "No Name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      buildInfo("Email", userData!["email"]),
                      buildInfo("Phone", userData!["phone"]),
                      buildInfo("Department", userData!["department"]),
                      buildInfo("Year", userData!["year"]),

                      const Spacer(),

                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.popUntil(
                              context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildInfo(String title, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$title: ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}