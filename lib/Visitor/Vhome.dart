import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:newarthub/Visitor/SignUp.dart';
class VHomePage extends StatefulWidget {
  const VHomePage({Key? key}) : super(key: key);

  @override
  State<VHomePage> createState() => _VHomePageState();
}

class _VHomePageState extends State<VHomePage> {
  final List<Map<String, dynamic>> artworks = [
    {
      'title': 'Starry Night',
      'artist': 'Vincent van Gogh',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/640px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
      'likes': 852,
    },
    {
      'title': 'Eiffel Tower',
      'artist': 'Claude Monet',
      'imageUrl': 'https://uploads7.wikiart.org/images/claude-monet/the-eiffel-tower-1878.jpg!Large.jpg',
      'likes': 1,
    },
  ];

  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchEmail();
  }

  void fetchEmail() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userEmail = user?.email ?? "Unknown User";
    });
  }

  void logoutUser() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: 500,
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Logo aligned to center-left
            const Padding(
              padding: EdgeInsets.only(left: 20,top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image(
                  image: AssetImage('assets/images/arthub_logo.png'),
                  height: 100,
                ),
              ),
            ),

            // Profile icon and email aligned to top-center
            Padding(
              padding: const EdgeInsets.symmetric(),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 80),
                  const SizedBox(height: 10),
                  Text(
                    userEmail ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/VisitorProfile');
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Booking History'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/BookingHistory');
                    },
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/VisitorSettings');
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Logout", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(), // dismiss dialog
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); // dismiss dialog
                                await FirebaseAuth.instance.signOut(); // <- Logout
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SigninPage()),
                                );
                              },
                              child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 0), // Space between AppBar and title
            const Center(
              child: Text(
                "ARTHUB",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10), // Space below the title

            // Upload Artwork Button


            // Artwork List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: artworks.length,
                itemBuilder: (context, index) {
                  final artwork = artworks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Image.network(
                            artwork['imageUrl'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artwork['artist'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.white54, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    artwork['likes'].toString(),
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
