import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> favouriteArtists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavourites();
  }

  Future<void> fetchFavourites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    final favRef = FirebaseDatabase.instance.ref('favourites/${user.uid}');
    final favSnapshot = await favRef.get();

    if (favSnapshot.exists) {
      final favData = Map<String, dynamic>.from(favSnapshot.value as Map);
      List<Map<String, dynamic>> artistsList = [];

      for (final artistId in favData.keys) {
        final artistRef = FirebaseDatabase.instance.ref('artists/$artistId');
        final artistSnapshot = await artistRef.get();

        if (artistSnapshot.exists) {
          final artistMap = Map<String, dynamic>.from(artistSnapshot.value as Map);
          artistMap['artistId'] = artistId;
          artistsList.add(artistMap);
        }
      }

      setState(() {
        favouriteArtists = artistsList;
        isLoading = false;
      });
    } else {
      setState(() {
        favouriteArtists = [];
        isLoading = false;
      });
    }
  }

  Future<void> toggleFavourite(String artistId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final favRef = FirebaseDatabase.instance.ref('favourites/${user.uid}/$artistId');

    final snapshot = await favRef.get();
    if (snapshot.exists) {
      // If already favourite, remove it
      await favRef.remove();
    } else {
      // Add as favourite
      await favRef.set(true);
    }

    await fetchFavourites(); // refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Favourites"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favouriteArtists.isEmpty
          ? const Center(child: Text("No favourites added yet."))
          : GridView.builder(
        padding: const EdgeInsets.all(16), // padding around grid
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // slightly taller cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: favouriteArtists.length,
        itemBuilder: (context, index) {
          final artist = favouriteArtists[index];
          final artistId = artist['artistId'] as String;

          String? imageUrl;

          if (artist.containsKey('profileImageUrl') &&
              (artist['profileImageUrl'] as String).isNotEmpty) {
            imageUrl = artist['profileImageUrl'] as String;
          } else {
            imageUrl = null; // No fallback to artwork image
          }

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null) // Show image only if profileImageUrl exists
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(child: Text("No image")),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist['bio'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artist['email'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

        },
      ),
    );
  }
}
