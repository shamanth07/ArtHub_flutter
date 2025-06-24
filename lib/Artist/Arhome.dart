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

      List<Map<String, dynamic>> tempArtworks = [];

      for (final entry in data.entries) {
        final artworkId = entry.key;
        final artwork = entry.value as Map<dynamic, dynamic>;

        int likesCount = 0;
        int commentsCount = 0;

        // Fetch likes and comments count from artworkInteractions
        final interactionRef = FirebaseDatabase.instance.ref("artworkInteractions/$artworkId");
        final interactionSnap = await interactionRef.get();

        if (interactionSnap.exists) {
          final interactionData = interactionSnap.value as Map<dynamic, dynamic>;

          // Likes count
          if (interactionData["likes"] != null && interactionData["likes"] is Map) {
            likesCount = (interactionData["likes"] as Map).length;
          }

          // Comments count
          if (interactionData["comments"] != null && interactionData["comments"] is Map) {
            commentsCount = (interactionData["comments"] as Map).length;
          }
        }

        tempArtworks.add({
          "artworkId": artworkId,
          "title": artwork["title"] ?? "",
          "artist": userEmail ?? "",
          "imageUrl": artwork["imageUrl"] ?? "",
          "likes": likesCount,
          "comments": commentsCount,
        });
      }

      setState(() {
        artworks = tempArtworks;
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
                      // Likes count
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

                      // Comments count with tap to open comment page
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentsPage(artworkId: artwork['artworkId']),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.comment, color: Colors.white54, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              (artwork['comments'] ?? 0).toString(),
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
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

// --- COMMENTS PAGE ---

class CommentsPage extends StatefulWidget {
  final String artworkId;

  const CommentsPage({Key? key, required this.artworkId}) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  List<Map<String, dynamic>> commentsList = [];
  bool isLoading = true;
  final TextEditingController _replyController = TextEditingController();
  String? replyingToCommentId;

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  Future<void> loadComments() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('artworkInteractions/${widget.artworkId}/comments')
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> temp = [];

      for (var entry in data.entries) {
        final commentData = entry.value as Map<dynamic, dynamic>;
        final userId = commentData['userId'] ?? '';
        String authorName = "Anonymous";

        // Try to fetch from users/ first
        if (userId.isNotEmpty) {
          final userSnap = await FirebaseDatabase.instance
              .ref('users/$userId/email')
              .get();

          if (userSnap.exists) {
            authorName = userSnap.value.toString();
          } else {
            // Fallback to artists/{userId}/name if not found in users/
            final artistSnap = await FirebaseDatabase.instance
                .ref('artists/$userId/name')
                .get();
            if (artistSnap.exists) {
              authorName = artistSnap.value.toString();
            }
          }
        }

        // Load replies
        List<Map<String, dynamic>> replies = [];
        if (commentData['replies'] != null) {
          final repliesMap = commentData['replies'] as Map<dynamic, dynamic>;
          for (var r in repliesMap.entries) {
            final reply = r.value as Map;
            String replyAuthor = "Anonymous";
            if (reply['userId'] != null) {
              final replyUserSnap = await FirebaseDatabase.instance
                  .ref('users/${reply['userId']}/email')
                  .get();
              if (replyUserSnap.exists) {
                replyAuthor = replyUserSnap.value.toString();
              } else {
                final fallbackSnap = await FirebaseDatabase.instance
                    .ref('artists/${reply['userId']}/name')
                    .get();
                if (fallbackSnap.exists) {
                  replyAuthor = fallbackSnap.value.toString();
                }
              }
            }

            replies.add({
              'text': reply['text'],
              'author': replyAuthor,
              'timestamp': reply['timestamp'],
            });
          }
        }

        temp.add({
          "commentId": entry.key,
          "text": commentData["comment"] ?? "",
          "author": authorName,
          "timestamp": commentData["timestamp"] ?? 0,
          "replies": replies,
        });
      }

      setState(() {
        commentsList = temp;
        isLoading = false;
      });
    } else {
      setState(() {
        commentsList = [];
        isLoading = false;
      });
    }
  }


  Future<void> addReply(String commentId, String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final replyRef = FirebaseDatabase.instance
        .ref('artworkInteractions/${widget.artworkId}/comments/$commentId/replies')
        .push();

    await replyRef.set({
      "text": text,
      "userId": currentUser.uid,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    _replyController.clear();
    replyingToCommentId = null;
    await loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: commentsList.length,
              itemBuilder: (context, index) {
                final comment = commentsList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment['text'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("By ${comment['author']}", style: const TextStyle(color: Colors.grey)),
                        Text("ID: ${comment['commentId']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),

                        // Show replies
                        if (comment['replies'] != null && comment['replies'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (comment['replies'] as List)
                                  .map((reply) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Text(
                                  "↳ ${reply['author']}: ${reply['text']}",
                                  style: const TextStyle(color: Colors.blueGrey),
                                ),
                              ))
                                  .toList(),
                            ),
                          ),

                        // Reply button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                replyingToCommentId = comment['commentId'];
                              });
                            },
                            child: const Text("Reply"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Reply input field
          if (replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_replyController.text.trim().isNotEmpty) {
                            addReply(replyingToCommentId!, _replyController.text.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        replyingToCommentId = null;
                        _replyController.clear();
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}