import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newarthub/Artist/uploadartwork.dart';
class ArtistHomePage extends StatelessWidget {
  final List<Map<String, dynamic>> artworks = [
    {
      'title': 'Starry Night',
      'artist': 'Vincent van Gogh',
      'imageUrl':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/640px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
      'likes': 852,
    },
    {
      'title': 'Eiffel Tower',
      'artist': 'Claude Monet',
      'imageUrl':
      'https://uploads7.wikiart.org/images/claude-monet/the-eiffel-tower-1878.jpg!Large.jpg',
      'likes': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Artist';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Profile Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        email,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications, size: 26),
                ],
              ),
            ),

            // Upload Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  UploadArtworkPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 40),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Upload Artwork',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Artwork List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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
                              topRight: Radius.circular(8)),
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
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artwork['artist'],
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
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
                                    style:
                                    const TextStyle(color: Colors.white54),
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
            )
          ],
        ),
      ),
    );
  }
}
