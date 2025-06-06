
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchArtistData();
  }

  void fetchArtistData() async {
    final ref = FirebaseDatabase.instance.ref('artists/${widget.artistId}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        artistData = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView, // You can change mode if you want
      );
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

    // Safely cast socialLinks to a Map
    final socialLinks = artistData!['socialLinks'] != null
        ? Map<String, dynamic>.from(artistData!['socialLinks'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(artistData!['name'] ?? 'Artist Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Show first painting image instead of profile image
            Builder(
              builder: (_) {
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

                if (paintingUrl != null && paintingUrl.isNotEmpty) {
                  return Image.network(
                    paintingUrl,
                    height: 200,
                    width: 500,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Container(
                    height: 200,
                    width: 500,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No Painting Available')),
                  );
                }
              },
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
