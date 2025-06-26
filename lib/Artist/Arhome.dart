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
    listenToInvitationStatusChanges();
  }
  String? _lastKnownStatus;

  Future<void> fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      userEmail = user.email;
      await fetchArtworksFromFirebase();
    }
  }
  void listenToInvitationStatusChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final artistId = user.uid;
    final invitationsRef = FirebaseDatabase.instance.ref('invitations');

    final snapshot = await invitationsRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>;

    String? mostRecentEventId;
    int mostRecentAppliedAt = 0;

    data.forEach((eventId, artistMap) {
      if (artistMap is Map && artistMap.containsKey(artistId)) {
        final artistEntry = artistMap[artistId] as Map<dynamic, dynamic>;
        final appliedAt = artistEntry['appliedAt'] ?? 0;

        if (appliedAt is int && appliedAt > mostRecentAppliedAt) {
          mostRecentAppliedAt = appliedAt;
          mostRecentEventId = eventId;
        }
      }
    });

    if (mostRecentEventId == null) return;

    final recentEventArtistRef = FirebaseDatabase.instance.ref('invitations/$mostRecentEventId/$artistId');

    recentEventArtistRef.onValue.listen((DatabaseEvent event) async {
      if (!event.snapshot.exists) return;

      final artistEntry = event.snapshot.value as Map<dynamic, dynamic>;
      final status = artistEntry['status'] ?? 'unknown';

      // Fetch event name dynamically here
      String eventName = mostRecentEventId!;

      final eventRef = FirebaseDatabase.instance.ref('events/$mostRecentEventId');
      final eventSnapshot = await eventRef.get();
      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.value as Map<dynamic, dynamic>;
        eventName = eventData['title'] ?? mostRecentEventId;
      }

      // Show notification only if status has changed
      if (_lastKnownStatus != status) {
        _lastKnownStatus = status;
        if (mounted) {
          showTopNotification(context, eventName, status);
        }
      }
    });
  }


// Helper method to show top-positioned notification
  void showTopNotification(BuildContext context, String eventName, String status) {
    final Color statusColor = status == 'accepted'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.orange;

    final IconData statusIcon = status == 'accepted'
        ? Icons.check_circle
        : status == 'rejected'
        ? Icons.cancel
        : Icons.hourglass_top;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Updated',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Your status for "$eventName" is now "$status"',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 5 seconds
    Future.delayed(Duration(seconds: 5)).then((_) => overlayEntry.remove());
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
  Future<int> fetchCommentCount(String artworkId) async {
    final snapshot = await FirebaseDatabase.instance
        .ref('artworkInteractions/$artworkId/comments')
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return data.length; // total number of comments
    }
    return 0;
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
                      IconButton(
                        icon: const Icon(Icons.comment, color: Colors.white54), // You can change the color or size
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.5, // Bottom half of the screen
                              child: CommentsPage(artworkId:artwork['artworkId']), // Pass the correct artwork ID
                            ),
                          );
                        },
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

            int replyTimestamp = 0;
            final rawTimestamp = reply['timestamp'];
            if (rawTimestamp is int) {
              replyTimestamp = rawTimestamp;
            } else if (rawTimestamp is double) {
              replyTimestamp = rawTimestamp.toInt();
            }

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
              'author': replyAuthor,
              'comment': reply['comment'] ?? '',
              'timestamp': replyTimestamp,
            });
          }

          // Sort replies by timestamp ascending
          replies.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
        }

        temp.add({
          "commentId": entry.key,
          "text": commentData["comment"] ?? "",
          "author": authorName,
          "timestamp": parseTimestamp(commentData["timestamp"]),
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

  int parseTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }

  Future<void> addReply(String commentId, String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final replyRef = FirebaseDatabase.instance
        .ref('artworkInteractions/${widget.artworkId}/comments/$commentId/replies')
        .push();

    await replyRef.set({
      "comment": text,
      "userId": currentUser.uid,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    _replyController.clear();
    replyingToCommentId = null;
    await loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...commentsList.map((comment) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment['author'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(comment['text']),
                  ...comment['replies'].map<Widget>((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("- ${reply['author']}: ${reply['comment']}"),
                        ],
                      ),
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        replyingToCommentId = comment['commentId'];
                      });
                    },
                    child: const Text("Reply"),
                  ),
                ],
              );
            }).toList(),
            if (replyingToCommentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration:
                        const InputDecoration(hintText: "Type your reply"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_replyController.text.trim().isNotEmpty) {
                          addReply(replyingToCommentId!, _replyController.text.trim());
                        }
                      },
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
