import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final deptController = TextEditingController();
  final yearController = TextEditingController();

  String selectedGender = "Male";
  bool isLoading = false;

  Future<void> signupUser() async {
    if (
      nameController.text.isEmpty ||
      emailController.text.isEmpty ||
      passwordController.text.isEmpty ||
      phoneController.text.isEmpty ||
      deptController.text.isEmpty ||
      yearController.text.isEmpty
    ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2. Firestore user data
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "department": deptController.text.trim(),
        "year": yearController.text.trim(),
        "gender": selectedGender,
        "createdAt": DateTime.now(),
      });

      if (!mounted) return;

      // 3. Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {

      String message = "Signup failed";

      if (e.code == "email-already-in-use") {
        message = "Email already exists";
      } else if (e.code == "weak-password") {
        message = "Password must be at least 6 characters";
      } else if (e.code == "invalid-email") {
        message = "Invalid email format";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    deptController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 60),

            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF243B6B),
              ),
            ),

            const SizedBox(height: 30),

            buildField(nameController, "Full Name"),
            buildField(emailController, "College Email"),
            buildField(passwordController, "Password", isPassword: true),
            buildField(phoneController, "Phone Number"),
            buildField(deptController, "Department"),
            buildField(yearController, "Year"),

            const SizedBox(height: 12),

            // 👇 GENDER DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : signupUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}