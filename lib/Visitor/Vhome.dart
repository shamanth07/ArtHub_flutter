import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';  // add firebase_database dependency
import 'package:newarthub/Visitor/VProfile.dart';
import 'package:newarthub/Visitor/SignUp.dart';

class VisitorHomePage extends StatefulWidget {
  const VisitorHomePage({super.key});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  String selectedCategory = 'Painting';
  final dbRef = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> artworks = [];
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  // To hold liked artworks by id locally for demo
  Set<String> likedArtworks = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    if (selectedCategory == 'Painting') {
      final artworksSnapshot = await dbRef.child('artists').get();
      List<Map<String, dynamic>> tempArtworks = [];

      if (artworksSnapshot.exists) {
        Map artistsMap = artworksSnapshot.value as Map;
        // Each artist contains artworks, flatten them
        artistsMap.forEach((artistId, artistData) {
          if (artistData['artworks'] != null) {
            Map artworksMap = artistData['artworks'] as Map;
            artworksMap.forEach((artworkId, artworkData) {
              tempArtworks.add({
                'id': artworkId,
                'title': artworkData['title'] ?? '',
                'imageUrl': artworkData['imageUrl'] ?? '',
              });
            });
          }
        });
      }

      setState(() {
        artworks = tempArtworks;
        isLoading = false;
      });
    } else if (selectedCategory == 'Events') {
      final eventsSnapshot = await dbRef.child('events').get();
      List<Map<String, dynamic>> tempEvents = [];

      if (eventsSnapshot.exists) {
        Map eventsMap = eventsSnapshot.value as Map;
        eventsMap.forEach((eventId, eventData) {
          tempEvents.add({
            'id': eventId,
            'title': eventData['title'] ?? '',
            'bannerImageUrl': eventData['bannerImageUrl'] ?? '',
            'eventDate': eventData['eventDate'] ?? '',
          });
        });
      }

      setState(() {
        events = tempEvents;
        isLoading = false;
      });
    }
  }

  void toggleLike(String artworkId) {
    setState(() {
      if (likedArtworks.contains(artworkId)) {
        likedArtworks.remove(artworkId);
      } else {
        likedArtworks.add(artworkId);
      }
    });
  }

  void onCommentTap(String artworkId) {
    // For now just show a simple snackbar. You can replace with real comment page.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment tapped for artwork $artworkId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      drawer: Drawer(
        width: 500,
        child: Column(
          children: [
            const SizedBox(height: 50),
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
                    userEmail ?? 'No email',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VProfilePage()),
                      );
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
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await FirebaseAuth.instance.signOut();
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
      appBar: AppBar(
        title: const Text("ARTHUB", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add filter logic here if needed
                  },
                  child: const Text("Filters"),
                ),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: ['Painting', 'Events'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                    fetchData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedCategory == 'Painting'
                ? artworks.isEmpty
                ? const Center(child: Text('No artworks to display.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                final artwork = artworks[index];
                final isLiked = likedArtworks.contains(artwork['id']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1, // square image like Instagram
                        child: artwork['imageUrl'] != ''
                            ? Image.network(
                          artwork['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                        )
                            : const Center(child: Icon(Icons.image_not_supported)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          artwork['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => toggleLike(artwork['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                              onPressed: () => onCommentTap(artwork['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
                : events.isEmpty
                ? const Center(child: Text('No events to display.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 2,
                        child: event['bannerImageUrl'] != ''
                            ? Image.network(
                          event['bannerImageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                        )
                            : const Center(child: Icon(Icons.image_not_supported)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          event['title'] ?? 'Untitled Event',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (event['eventDate'] != null && event['eventDate'] != '')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          child: Text(
                            _formatEventDate(event['eventDate']),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(dynamic timestamp) {
    try {
      // Assume eventDate is a timestamp in milliseconds
      int millis = 0;
      if (timestamp is int) {
        millis = timestamp;
      } else if (timestamp is String) {
        millis = int.tryParse(timestamp) ?? 0;
      }
      if (millis == 0) return '';

      final date = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
