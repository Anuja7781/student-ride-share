import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue.shade900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text('Student Ride', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Safe & Affordable Rides', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}