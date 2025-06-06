import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newarthub/Artist/uploadartwork.dart';
import 'package:newarthub/Artist/ArSignUp.dart';
import 'package:newarthub/Artist/ArProfile.dart';
import 'package:newarthub/Artist/EditArtwork.dart';
import 'package:newarthub/Artist/ApplyEvent.dart';
import 'package:newarthub/Artist/ArSettings.dart';
import 'package:newarthub/Artist/ArtistStatus.dart';
class ArtistHomePage extends StatefulWidget {
  const ArtistHomePage({Key? key}) : super(key: key);

  @override
  State<ArtistHomePage> createState() => _ArtistHomePageState();
}

class _ArtistHomePageState extends State<ArtistHomePage> {
  String? userEmail;
  String? userId;
  List<Map<String, dynamic>> artworks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      userEmail = user.email;
      await fetchArtworksFromFirebase();
    }
  }

  Future<void> fetchArtworksFromFirebase() async {
    final ref = FirebaseDatabase.instance.ref("artists/$userId/artworks");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        artworks = data.entries.map<Map<String, dynamic>>((entry) {
          final artwork = entry.value as Map<dynamic, dynamic>;
          return {
            "artworkId": entry.key,
            "title": artwork["title"] ?? "",
            "artist": userEmail ?? "",
            "imageUrl": artwork["imageUrl"] ?? "",
            "likes": artwork["likes"] ?? 0,
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        artworks = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteArtwork(String artworkId) async {
    final artistRef = FirebaseDatabase.instance.ref("artists/$userId/artworks/$artworkId");
    final globalRef = FirebaseDatabase.instance.ref("artworks/$artworkId");

    await artistRef.remove();
    await globalRef.remove();

    await fetchArtworksFromFirebase();
  }

  void confirmDelete(BuildContext context, String artworkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: const Text('Are you sure you want to delete this artwork from both artist and global lists?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              deleteArtwork(artworkId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      drawer: buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            const Center(
              child: Text(
                "Artist Home",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadArtworkPage()),
                  ).then((_) => fetchArtworksFromFirebase());
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
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: RefreshIndicator(
                onRefresh: fetchArtworksFromFirebase,
                child: artworks.isEmpty
                    ? const Center(child: Text("No artworks uploaded yet."))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = artworks[index];
                    return buildArtworkCard(artwork);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildArtworkCard(Map<String, dynamic> artwork) {
    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditArtworkPage(
              artworkId: artwork['artworkId'],
              title: artwork['title'],
              imageUrl: artwork['imageUrl'],
            ),
          ),
        );

        if (shouldRefresh == true) {
          fetchArtworksFromFirebase();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (artwork['imageUrl'] != null)
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
                    artwork['title'] ?? 'Untitled',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artwork['artist'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white54, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            (artwork['likes'] ?? 0).toString(),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(context, artwork['artworkId']),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      width: 500,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image(
                image: AssetImage('assets/images/arthub_logo.png'),
                height: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(),
            child: Column(
              children: [
                const Icon(Icons.account_circle, size: 80),
                const SizedBox(height: 5),
                Text(
                  userEmail ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtistProfilePage())),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Likes'),
                  onTap: () => Navigator.pushNamed(context, '/artistLikes'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Apply For Event'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyEventPage())),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Status'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicationStatusPage())),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => Navigator.push(context,  MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ArSigninPage()),
                              );
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
