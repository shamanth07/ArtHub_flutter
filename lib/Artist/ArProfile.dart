
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'uploadartwork.dart';
import 'package:newarthub/Artist/ArChangePassword.dart';
import 'package:newarthub/Artist/EditProfile.dart';

class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  final database = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  String name = "";
  String email = "";
  String bio = "";
  String website = "";
  String instagram = "";
  String? profileImageUrl;

  List<Map> artworks = [];

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchArtistArtworks();
  }

  Future<void> fetchProfileData() async {
    if (user == null) return;
    final snapshot = await database.child('artists/${user!.uid}').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        bio = data['bio'] ?? '';
        website = data['socialLinks']?['website'] ?? '';
        instagram = data['socialLinks']?['instagram'] ?? '';
        profileImageUrl = data['profileImageUrl'];
      });
    } else {
      final newArtist = {
        'name': user!.displayName ?? '',
        'email': user!.email ?? '',
        'role': 'artist',
        'bio': '',
        'profileImageUrl': '',
        'socialLinks': {
          'website': '',
          'instagram': ''
        },
        'artworks': {}
      };

      await database.child('artists/${user!.uid}').set(newArtist);

      setState(() {
        name = newArtist['name'] as String? ?? '';
        email = newArtist['email'] as String? ?? '';
        bio = '';
        website = '';
        instagram = '';
        profileImageUrl = '';
      });
    }
  }

  Future<void> fetchArtistArtworks() async {
    if (user == null) return;
    final snapshot = await database.child('artists/${user!.uid}/artworks').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final loadedArtworks = <Map>[];
      data.forEach((key, value) {
        loadedArtworks.add(Map<String, dynamic>.from(value));
      });
      setState(() {
        artworks = loadedArtworks;
      });
    } else {
      setState(() {
        artworks = [];
      });
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      print("URL is empty");
      return;
    }

    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      print("Launched: $launched");
    } else {
      print("Could NOT launch: $uri");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final imageWidget = profileImageUrl != null && profileImageUrl!.isNotEmpty
        ? CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(profileImageUrl!),
    )
        : const CircleAvatar(
      radius: 50,
      child: Icon(Icons.account_circle, size: 60),
    );

    const linkStyle = TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist Profile"),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(child: imageWidget),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$name (Artist)",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditArtistProfilePage()),
                    );
                    fetchProfileData();
                  },
                  child: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.blueGrey)),
            const Divider(height: 30),
            const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(bio),
            const Divider(height: 30),
            const Text("Social Links", style: TextStyle(fontWeight: FontWeight.bold)),

            // Website Link
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Website"),
              subtitle: Text(
                website.isNotEmpty ? website : "Not provided",
                style: website.isNotEmpty ? linkStyle : const TextStyle(color: Colors.grey),
              ),
              onTap: website.isNotEmpty ? () => _launchURL(website) : null,
            ),




            // Instagram Link
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Instagram"),
              subtitle: Text(
                instagram.isNotEmpty ? instagram : "Not provided",
                style: instagram.isNotEmpty ? linkStyle : const TextStyle(color: Colors.grey),
              ),
              onTap: instagram.isNotEmpty ? () => _launchURL(instagram) : null,
            ),

            const Divider(height: 30),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
              child: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
