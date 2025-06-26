import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:newarthub/Admin/CreatEvent.dart';
import 'package:newarthub/Admin/AdLogin.dart';
import 'package:newarthub/Admin/EditEventPage.dart';
import 'package:newarthub/Admin/AdProfile.dart';
import 'package:newarthub/Admin/Reports.dart';
import 'package:newarthub/Admin/invitations.dart';
import 'package:newarthub/Admin/Settings.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final DatabaseReference eventsRef = FirebaseDatabase.instance.ref("events");
  final DatabaseReference commentsRef = FirebaseDatabase.instance.ref("eventComments");

  List<Map<dynamic, dynamic>> events = [];
  Map<String, int> commentCounts = {};

  @override
  void initState() {
    super.initState();
    fetchEvents();
    fetchCommentCountsLive();
  }
  void showEventCommentsBottomSheet(String eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: EventCommentsSheet(eventId: eventId),
        );
      },
    );
  }

  void fetchEvents() {
    eventsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          events = data.entries.map((entry) {
            return {
              'key': entry.key,
              ...Map<String, dynamic>.from(entry.value),
            };
          }).toList();
        });
      } else {
        setState(() {
          events = [];
        });
      }
    });
  }

  void fetchCommentCountsLive() {
    commentsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final Map<String, int> tempCounts = {};
        data.forEach((eventId, commentData) {
          if (commentData is Map) {
            tempCounts[eventId] = commentData.length;
          }
        });

        setState(() {
          commentCounts = tempCounts;
        });
      }
    });
  }

  void deleteEvent(String key) async {
    await eventsRef.child(key).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event deleted")),
    );
  }

  void editEvent(Map<dynamic, dynamic> event) async {
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(
          eventKey: event['key'],
          eventData: event,
        ),
      ),
    );

    if (updated == true) {
      fetchEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated successfully")),
      );
    }
  }

  String formatDate(dynamic timestamp) {
    final int millis = (timestamp is double)
        ? timestamp.toInt()
        : (timestamp is int)
        ? timestamp
        : 0;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: 500,
        child: ListView(
          children: [
            const SizedBox(height: 50),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Image(
                image: AssetImage('assets/images/arthub_logo.png'),
                height: 80,
              ),
            ),
            const Center(
              child: Text("Abhishek (Admin)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Divider(),
            drawerItem(Icons.person, "Profile", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfilePage()));
            }),
            const Divider(),
            drawerItem(Icons.add_box, "Create Event", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventPage()));
            }),
            const Divider(),
            drawerItem(Icons.mail, "Invitations", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminInvitationsPage()));
            }),
            const Divider(),
            drawerItem(Icons.settings, "Settings", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            }),
            const Divider(),
            drawerItem(Icons.report, "Reports", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReportsPage()));
            }),
            const Divider(),
            drawerItem(Icons.logout, "Logout", () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AdSignUpPage()),
                        );
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Event button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventPage()));
                },
                child: const Text("Create Event", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 25),
            const Text("Created Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text("No events found"))
                  : ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final commentCount = commentCounts[event['key']] ?? 0;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          event['bannerImageUrl'] ?? 'https://via.placeholder.com/60',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(formatDate(event['eventDate'])),
                            Text(event['time'] ?? ''),
                            Text("Max Artists: ${event['maxArtists']}"),
                            TextButton(
                              onPressed: () => showEventCommentsBottomSheet(event['key']),
                              child: const Text("Comments"),
                            ),

                          ],
                        ),
                      ),
                      // Actions
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => editEvent(event),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => deleteEvent(event['key']),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
class EventCommentsSheet extends StatefulWidget {
  final String eventId;

  const EventCommentsSheet({super.key, required this.eventId});

  @override
  State<EventCommentsSheet> createState() => _EventCommentsSheetState();
}

class _EventCommentsSheetState extends State<EventCommentsSheet> {
  final DatabaseReference commentsRef = FirebaseDatabase.instance.ref("eventComments");
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    listenForComments();
  }
  void listenForComments() {
    commentsRef.child(widget.eventId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          if (value is Map) {
            final item = Map<String, dynamic>.from(value);

            item['id'] = key.toString();

            // Parse replies safely
            if (item['replies'] is Map) {
              final repliesRaw = item['replies'] as Map;
              final replies = <String, Map<String, dynamic>>{};
              repliesRaw.forEach((replyKey, replyValue) {
                if (replyValue is Map) {
                  replies[replyKey.toString()] =
                  Map<String, dynamic>.from(replyValue);
                }
              });
              item['replies'] = replies;
            } else {
              item['replies'] = <String, Map<String, dynamic>>{};
            }

            temp.add(item);
          }
        });

        setState(() {
          comments = temp.reversed.toList();
        });
      } else {
        setState(() {
          comments = [];
        });
      }
    });
  }


  String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  void sendReply(String commentId, String replyText) async {
    final userEmail = "abhishek991116@gmail.com"; // Ideally use FirebaseAuth.instance.currentUser?.email
    final replyId = commentsRef.push().key!;
    final replyData = {
      "comment": replyText,  // <-- match Firebase structure
      "userEmail": userEmail,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };


    await commentsRef
        .child(widget.eventId)
        .child(commentId)
        .child("replies")
        .child(replyId)
        .set(replyData);
  }

  void showReplyDialog(String commentId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reply to Comment"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Type your reply here..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                sendReply(commentId, text);
              }
              Navigator.pop(context);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text("No comments yet"))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final comment = comments[index];
                final replies = comment['replies'] as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(comment['comment'] ?? ''),
                      subtitle: Text(comment['userEmail'] ?? ''),
                      trailing: Text(
                        formatTime(comment['timestamp'] ?? 0),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        children: replies.entries.map((entry) {
                          final reply = Map<String, dynamic>.from(entry.value);
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.reply, size: 18, color: Colors.grey),
                            title: Text(reply['comment'] ?? ''),
                            subtitle: Text(reply['userEmail'] ?? ''),
                            trailing: Text(
                              formatTime(reply['timestamp'] ?? 0),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showReplyDialog(comment['id']),
                        child: const Text("Reply"),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}