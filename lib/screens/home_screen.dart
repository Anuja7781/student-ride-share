import 'package:flutter/material.dart';
import '../services/firestore_service.dart'; 
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rides")),
      body: StreamBuilder(stream: FirestoreService().getRides(),
  builder: (context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final rides = snapshot.data.docs;

    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final data = rides[index].data() as Map<String, dynamic>;

        return ListTile(
          title: Text("${data['source']} → ${data['destination']}"),
          subtitle: Text("₹${data['fare']} | Seats: ${data['seats']}"),
        );
      },
    );
  },),
    );
  }
}