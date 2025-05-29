import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newarthub/Visitor/VProfile.dart';
import 'package:newarthub/Visitor/SignUp.dart';
import 'package:newarthub/Visitor/VSettings.dart';

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

  Set<String> likedArtworks = {};
  final TextEditingController searchController = TextEditingController();

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment tapped for artwork $artworkId')),
    );
  }

  List<Map<String, dynamic>> getFilteredItems() {
    String query = searchController.text.toLowerCase();
    if (selectedCategory == 'Painting') {
      return artworks
          .where((art) => art['title'].toLowerCase().contains(query))
          .toList();
    } else {
      return events
          .where((event) => event['title'].toLowerCase().contains(query))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    final filteredItems = getFilteredItems();

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
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
                  onPressed: () {},
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search ${selectedCategory == 'Painting' ? 'artworks' : 'events'}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) {
                setState(() {}); // Triggers rebuild for filtering
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? Center(
              child: Text(
                selectedCategory == 'Painting'
                    ? 'No artworks to display.'
                    : 'No events to display.',
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                if (selectedCategory == 'Painting') {
                  final isLiked = likedArtworks.contains(item['id']);
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
                          aspectRatio: 1,
                          child: item['imageUrl'] != ''
                              ? Image.network(
                            item['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image)),
                          )
                              : const Center(child: Icon(Icons.image_not_supported)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            item['title'] ?? 'Untitled',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
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
                                onPressed: () => toggleLike(item['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                                onPressed: () => onCommentTap(item['id']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
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
                          child: item['bannerImageUrl'] != ''
                              ? Image.network(
                            item['bannerImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image)),
                          )
                              : const Center(child: Icon(Icons.image_not_supported)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            item['title'] ?? 'Untitled Event',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (item['eventDate'] != null && item['eventDate'] != '')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _formatEventDate(item['eventDate']),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(dynamic timestamp) {
    try {
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
