import 'package:flutter/material.dart';
import 'package:art_hub/Admin/CreatEvent.dart';
import 'package:art_hub/Admin/AdLogin.dart';
class AdminEventsPage extends StatelessWidget {
  const AdminEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: const [DrawerHeader(child: Text("Menu"))],
        ),
      ),

      appBar: AppBar(
        toolbarHeight: 70, // Increase the height of the AppBar
        title: const Padding(
          padding: EdgeInsets.only(top: 50), // Move text slightly downward
          child: Text(
            "Admin",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
          ),
        ),

        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal:20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Create Event Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateEventPage()),
                  );
                },
                child: const Text(
                  "Create Event",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Created Events Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Created Events",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),

            // Event Cards (Example)


            const Spacer(), // Pushes Back button to the bottom

            // Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdSignUpPage()),
                  );
                },
                child: const Text(
                  "Back",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}