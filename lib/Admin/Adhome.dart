// admin_events_page.dart (Updated with RSVP count based on event title)

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:newarthub/Admin/CreatEvent.dart';
import 'package:newarthub/Admin/AdLogin.dart';
import 'package:newarthub/Admin/EditEventPage.dart';
import 'package:newarthub/Admin/AdProfile.dart';
import 'package:newarthub/Admin/invitations.dart';
import 'package:newarthub/Admin/Settings.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final DatabaseReference eventsRef = FirebaseDatabase.instance.ref("events");
  final DatabaseReference rsvpRef = FirebaseDatabase.instance.ref("rsvp");
  List<Map<dynamic, dynamic>> events = [];
  Map<String, int> rsvpCounts = {};

  @override
  void initState() {
    super.initState();
    fetchEvents();
    fetchRSVPCounts();
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

  void fetchRSVPCounts() async {
    final countsRef = FirebaseDatabase.instance.ref('rsvp_counts');
    final snapshot = await countsRef.get();

    if (snapshot.exists) {
      final Map<String, int> tempCounts = {};
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((eventTitle, countMap) {
        if (countMap is Map && countMap['attending'] is int) {
          tempCounts[eventTitle] = countMap['attending'];
        }
      });

      setState(() {
        rsvpCounts = tempCounts;
      });
    } else {
      setState(() {
        rsvpCounts = {};
      });
    }
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
        SnackBar(content: Text("Event updated successfully")),
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
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        width: 500,
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image(
                  image: AssetImage('assets/images/arthub_logo.png'),
                  height: 100,
                ),
              ),
            ),
            const Text("Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey,
              child: Text("Image", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            const Text("Abhishek(Admin)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 30),
            drawerItem(Icons.person, "Profile", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfilePage()));
            }),
            drawerItem(Icons.calendar_today, "Create Event", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventPage()));
            }),
            drawerItem(Icons.calendar_today, "Invitations", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminInvitationsPage()));
            }),
            drawerItem(Icons.insert_drive_file, "Reports", () {}),
            drawerItem(Icons.settings, "Settings", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            }),
            drawerItem(Icons.logout, "Logout", () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventPage()));
                },
                child: const Text("Create Event", style: TextStyle(fontSize: 20, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Created Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text("No events found"))
                  : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventDate = event['eventDate'] ?? 0;
                  final rsvpCount = rsvpCounts[event['title']] ?? 0;
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['title'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(event['description'] ?? ''),
                          const SizedBox(height: 6),
                          Text("Date: ${formatDate(eventDate)}"),
                          Text("Time: ${event['time']}"),
                          Text("Max Artists: ${event['maxArtists']}"),
                          Text("RSVP Count: $rsvpCount"),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => editEvent(event),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                              ),
                              TextButton.icon(
                                onPressed: () => deleteEvent(event['key']),
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdSignUpPage()));
                },
                child: const Text("Back", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          onTap: onTap,
        ),
        const Divider(thickness: 1),
      ],
    );
  }
}