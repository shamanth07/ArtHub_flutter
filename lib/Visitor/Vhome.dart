import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:newarthub/Visitor/BookingHistory.dart';
import 'package:newarthub/Visitor/VProfile.dart';
import 'package:newarthub/Visitor/SignUp.dart';
import 'package:newarthub/Visitor/VSettings.dart';
import 'package:newarthub/Visitor/BookEvent.dart';
import 'package:newarthub/Artist/ArtistDetailPage.dart';
import 'package:newarthub/Visitor/Favourites.dart';
class VisitorHomePage extends StatefulWidget {
  const VisitorHomePage({super.key});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  String selectedCategory = 'Art Discovery';
  final dbRef = FirebaseDatabase.instance.ref();
  String? userEmail;
  List<Map<String, dynamic>> artworks = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> allArtworks = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  @override

  Future<void> fetchArtworks() async {
    DatabaseReference artworksRef = FirebaseDatabase.instance.ref().child('artists');

    final snapshot = await artworksRef.get();
    List<Map<String, dynamic>> tempArtworks = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((artistId, artistData) {
        final artistMap = Map<String, dynamic>.from(artistData);
        final artworks = artistMap['artworks'] as Map?;

        if (artworks != null) {
          artworks.forEach((artworkId, artworkData) {
            final artworkMap = Map<String, dynamic>.from(artworkData);
            artworkMap['id'] = artworkId;
            artworkMap['artistId'] = artistId;                // ✅ attach artistId
            artworkMap['category'] = artworkMap['category'];  // ✅ ensure category is attached

            tempArtworks.add(artworkMap);
          });
        }
      });

      setState(() {
        allArtworks = tempArtworks;
        filteredItems = allArtworks;
      });
    }
  }
  Future<void> _refreshData() async {
    await fetchArtworks();
  }

  Future<int> getLikeCount(String artworkId) async {
    final snapshot = await dbRef.child('artworkInteractions/$artworkId/likes').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).length;
    }
    return 0;
  }

  final TextEditingController searchController = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userEmail = user?.email;
    });
    fetchData();
    fetchArtworks();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    if (selectedCategory == 'Art Discovery') {
      final snapshot = await dbRef.child('artists').get();
      List<Map<String, dynamic>> tempArtworks = [];

      if (snapshot.exists && snapshot.value is Map) {
        final artistsMap = snapshot.value as Map;
        artistsMap.forEach((artistId, artistData) {
          if (artistData is Map &&
              artistData['artworks'] != null &&
              artistData['artworks'] is Map) {
            final artworksMap = artistData['artworks'] as Map;
            artworksMap.forEach((artworkId, artworkData) {
              if (artworkData is Map) {
                tempArtworks.add({
                  'id': artworkId,
                  'title': artworkData['title'] ?? '',
                  'imageUrl': artworkData['imageUrl'] ?? '',
                  'artistId': artistId,
                  // <--- ADD THIS
                  'category': artworkData['category'] ?? 'paintings',
                  // See next fix
                });
              }
              });
            }
        });
      }

      setState(() {
        artworks = tempArtworks;
        isLoading = false;
      });
    } else if (selectedCategory == 'Events') {
      final snapshot = await dbRef.child('events').get();
      List<Map<String, dynamic>> tempEvents = [];

      if (snapshot.exists && snapshot.value is Map) {
        final eventsMap = snapshot.value as Map;
        eventsMap.forEach((eventId, eventData) {
          if (eventData is Map) {
            final rawDate = eventData['eventDate'];
            final timestamp = (rawDate is int)
                ? rawDate
                : int.tryParse(rawDate?.toString() ?? '') ?? 0;

            tempEvents.add({
              'id': eventId,
              'title': eventData['title'] ?? '',
              'bannerImageUrl': eventData['bannerImageUrl'] ?? '',
              'eventDateFormatted': timestamp != 0
                  ? DateFormat('MMM dd, yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(timestamp))
                  : 'Date not available',
              'eventDate': timestamp,
              'description': eventData['description'] ?? '',
              'time': eventData['time'] ?? '',
              'maxArtists': eventData['maxArtists']?.toString() ?? '',
              'location': eventData['location'] ?? 'Not available',
              'ticketPrice': eventData['ticketPrice'] ?? 0,
            });
          }
        });
      }

      setState(() {
        events = tempEvents;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredItems() {
    final query = searchController.text.toLowerCase();
    return selectedCategory == 'Art Discovery'
        ? artworks
        .where((art) => art['title'].toLowerCase().contains(query))
        .toList()
        : events
        .where((event) => event['title'].toLowerCase().contains(query))
        .toList();
  }

  Future<void> toggleLike(String artworkId) async {
    final likeRef =
    dbRef.child('artworkInteractions/$artworkId/likes/$userId');
    final snapshot = await likeRef.get();

    if (snapshot.exists) {
      await likeRef.remove();
    } else {
      await likeRef.set(true);
    }

    setState(() {});
  }

  Future<bool> isLiked(String artworkId) async {
    final snapshot = await dbRef
        .child('artworkInteractions/$artworkId/likes/$userId')
        .get();
    return snapshot.exists;
  }

  Future<int> getCommentCount(String artworkId) async {
    final snapshot =
    await dbRef.child('artworkInteractions/$artworkId/comments').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).length;
    }
    return 0;
  }


  Future<List<Map<String, dynamic>>> fetchComments(String artworkId) async {
    final snapshot =
    await dbRef.child('artworkInteractions/$artworkId/comments').get();
    List<Map<String, dynamic>> comments = [];

    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;

      for (final entry in data.entries) {
        final commentData = entry.value;
        if (commentData is Map) {
          final userId = commentData['userId'];
          final emailSnapshot = await dbRef.child('users/$userId/email').get();
          final userEmail = emailSnapshot.value?.toString() ?? 'Unknown user';

          comments.add({
            'comment': commentData['comment'] ?? '',
            'userEmail': userEmail,
            'timestamp': commentData['timestamp'] ?? 0,
          });
        }
      }

      comments.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    }

    return comments;
  }

  Future<void> addComment(String artworkId, String comment) async {
    if (comment.trim().isEmpty) return;
    final commentRef =
    dbRef.child('artworkInteractions/$artworkId/comments').push();
    await commentRef.set({
      'userId': userId,

      'comment': comment,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    setState(() {});
  }

  void showCommentDialog(String artworkId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text("Comments",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchComments(artworkId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Center(child: Text("No comments yet."));
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final comment = comments[index];
                        final timestamp = DateTime.fromMillisecondsSinceEpoch(
                            comment['timestamp']);
                        final time = DateFormat('MMM d, h:mm a').format(timestamp);
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(comment['comment']),
                          subtitle: Text("${comment['userEmail']}\n${DateFormat('MMM d, h:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(comment['timestamp']),
                          )}"),
                        );

                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration:
                        const InputDecoration(hintText: "Add a comment"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        addComment(artworkId, controller.text);
                        controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText:
          'Search ${selectedCategory == 'Art Discovery' ? 'artworks' : 'events'}...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(onPressed: () {}, child: const Text("Filters")),
          DropdownButton<String>(
            value: selectedCategory,
            items: ['Art Discovery', 'Events']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCategory = value;
                });
                fetchData();
              }
            },
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(title: const Text("ARTHUB"));

  }

  Drawer buildDrawer(String? email) {
    return Drawer(
      width: 500,
      child: ListView(
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
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VProfilePage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('BookingHistory'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BookingHistoryPage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Favourites'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavouritesPage())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
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
          const Divider(),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final filteredItems = getFilteredItems();
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      drawer: buildDrawer(userEmail),
      appBar: buildAppBar(),
      body: Column(
          children: [
          buildTopBar(),
      const SizedBox(height: 10),
      buildSearchBar(),
      const SizedBox(height: 10),
      Expanded(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchArtworks, // your async data-fetching function
          child: filteredItems.isEmpty
              ? ListView( // Required because RefreshIndicator needs a scrollable widget
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Text(
                    selectedCategory == 'Art Discovery'
                        ? 'No artworks to display.'
                        : 'No events to display.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredItems.length,
              itemBuilder: (_, index) {
                final item = filteredItems[index];
                final id = item['id'];



                return GestureDetector(
                    onTap: () {
                      final artistId = item['artistId'];
                      final category = item['category'];

                      print("Tapped item. Category: $category, artistId: $artistId");

                      if (artistId != null && artistId is String) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistDetailsPage(artistId: artistId),
                          ),
                        );
                      } else {
                        print("Navigation condition failed.");
                      }
                    },



                    child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: selectedCategory == 'Events'
                              ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookEventPage(
                                title: item['title'],
                                description:
                                item['description'],
                                imageUrl:
                                item['bannerImageUrl'],
                                location: item['location'],
                                ticketPrice:
                                (item['ticketPrice']
                                as num?)
                                    ?.toDouble() ??
                                    0.0,
                                date: item['eventDate'] != 0
                                    ? DateTime
                                    .fromMillisecondsSinceEpoch(
                                    item['eventDate'])
                                    .toString()
                                    .split(' ')[0]
                                    : 'Not available',
                                time: item['time'],
                              ),
                            ),
                          )
                              : null,
                          child: item[selectedCategory == 'Art Discovery'
                              ? 'imageUrl'
                              : 'bannerImageUrl'] !=
                              ''
                              ? Image.network(
                            item[selectedCategory == 'Art Discovery'
                                ? 'imageUrl'
                                : 'bannerImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(
                                Icons.broken_image),
                          )
                              : Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons
                                    .image_not_supported)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(item['title'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (selectedCategory == 'Events') ...[
                              Text("Date: ${item['eventDateFormatted']}"),
                              Text("Time: ${item['time']}"),
                              Text("Description: ${item['description']}"),
                            ],
                            if (selectedCategory == 'Art Discovery') ...[
                              const SizedBox(height: 10),
                              FutureBuilder<int>(
                                future: getLikeCount(id),
                                builder: (context, snapshot) {
                                  final likeCount = snapshot.data ?? 0;
                                  return Row(
                                    children: [
                                      FutureBuilder<bool>(
                                        future: isLiked(id),
                                        builder: (context, snapshot) {
                                          final liked = snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              liked ? Icons.favorite : Icons.favorite_border,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => toggleLike(id),
                                          );
                                        },
                                      ),
                                      Text('$likeCount'),
                                      const SizedBox(width: 16),
                                      FutureBuilder<int>(
                                        future: getCommentCount(id),
                                        builder: (_, snap) {
                                          final count = snap.data ?? 0;
                                          return Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.comment),
                                                onPressed: () => showCommentDialog(id),
                                              ),
                                              Text('$count'),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              )

                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                );
              },
            ),
          ),
      )
        ],
      ),
    );
  }
}
