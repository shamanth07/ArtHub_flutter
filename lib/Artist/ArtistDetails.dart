import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtistDetailsPage extends StatefulWidget {
  final String artistId;

  const ArtistDetailsPage({super.key, required this.artistId});

  @override
  State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends State<ArtistDetailsPage> {
  Map<dynamic, dynamic>? artistData;
  bool isLoading = true;

  // Use FirebaseAuth to get current user id dynamically
  String? currentUserId;

  final DatabaseReference favouritesRef = FirebaseDatabase.instance.ref('favourites');

  bool isFavourite = false;
  bool favouriteLoading = true;

  @override
  void initState() {
    super.initState();
    // Get current user id safely
    currentUserId = FirebaseAuth.instance.currentUser?.uid;

    fetchArtistData();

    if (currentUserId != null) {
      checkIfFavourite();
    } else {
      // No logged in user
      setState(() {
        favouriteLoading = false;
      });
    }
  }

  Future<void> fetchArtistData() async {
    try {
      final ref = FirebaseDatabase.instance.ref('artists/${widget.artistId}');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        setState(() {
          artistData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          artistData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        artistData = null;
        isLoading = false;
      });
      print("Error fetching artist data: $e");
    }
  }

  Future<void> checkIfFavourite() async {
    if (currentUserId == null) return;

    try {
      final favSnapshot = await favouritesRef.child('$currentUserId/${widget.artistId}').get();

      setState(() {
        isFavourite = favSnapshot.exists && favSnapshot.value == true;
        favouriteLoading = false;
      });
    } catch (e) {
      setState(() {
        favouriteLoading = false;
      });
      print("Error checking favourite status: $e");
    }
  }

  Future<void> toggleFavourite() async {
    if (currentUserId == null) return;

    setState(() {
      favouriteLoading = true;
    });

    try {
      if (isFavourite) {
        await favouritesRef.child('$currentUserId/${widget.artistId}').remove();
      } else {
        await favouritesRef.child('$currentUserId/${widget.artistId}').set(true);
      }
      setState(() {
        isFavourite = !isFavourite;
        favouriteLoading = false;
      });
    } catch (e) {
      setState(() {
        favouriteLoading = false;
      });
      print("Error toggling favourite: $e");
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      print('Invalid URL: $url');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      print('Cannot launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (artistData == null) {
      return const Scaffold(
        body: Center(child: Text("Artist not found")),
      );
    }

    final socialLinks = artistData!['socialLinks'] != null
        ? Map<String, dynamic>.from(artistData!['socialLinks'])
        : null;

    // Safely get paintingUrl
    String? paintingUrl;
    if (artistData!['artworks'] != null && artistData!['artworks'] is Map) {
      final artworksMap = artistData!['artworks'] as Map;
      if (artworksMap.isNotEmpty) {
        final firstArtwork = artworksMap.values.first;
        if (firstArtwork is Map && firstArtwork['imageUrl'] != null) {
          paintingUrl = firstArtwork['imageUrl'] as String;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(artistData!['name'] ?? 'Artist Details'),
        actions: [
          favouriteLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
              : IconButton(
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: isFavourite ? Colors.red : Colors.black,
            ),
            onPressed: toggleFavourite,
            tooltip:
            isFavourite ? 'Remove from favourites' : 'Add to favourites',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (paintingUrl != null && paintingUrl.isNotEmpty)
              Image.network(
                paintingUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No Painting Available')),
                  );
                },
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(child: Text('No Painting Available')),
              ),
            const SizedBox(height: 16),
            Text(
              artistData!['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              artistData!['bio'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(artistData!['email'] ?? ''),
            ),
            const SizedBox(height: 16),
            if (socialLinks != null && socialLinks['instagram'] != null)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Instagram'),
                subtitle: Text(socialLinks['instagram'] as String),
                onTap: () => _launchURL(socialLinks['instagram'] as String),
              ),
            if (socialLinks != null && socialLinks['website'] != null)
              ListTile(
                leading: const Icon(Icons.web),
                title: const Text('Website'),
                subtitle: Text(socialLinks['website'] as String),
                onTap: () => _launchURL(socialLinks['website'] as String),
              ),
          ],
        ),
      ),
    );
  }
}
