// apply_event_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ApplyEventPage extends StatefulWidget {
  const ApplyEventPage({super.key});

  @override
  State<ApplyEventPage> createState() => _ApplyEventPageState();
}

class _ApplyEventPageState extends State<ApplyEventPage> {
  final DatabaseReference _eventsRef = FirebaseDatabase.instance.ref().child('events');

  String artistId = '';
  String artistName = '';
  String artistEmail = '';
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    initializeUserData();
  }

  Future<void> initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      artistId = user.uid;
      artistEmail = user.email ?? '';

      final nameSnapshot = await FirebaseDatabase.instance.ref('artists/$artistId/name').get();
      artistName = nameSnapshot.exists ? nameSnapshot.value as String : 'Unknown Artist';

      fetchEvents();
    }
  }

  Future<void> fetchEvents() async {
    final snapshot = await _eventsRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final filteredEvents = await Future.wait(data.entries.map((entry) async {
        final eventData = Map<String, dynamic>.from(entry.value);
        final eventId = entry.key;

        final inviteSnapshot = await FirebaseDatabase.instance
            .ref('invitations/$eventId/$artistId')
            .get();

        if (!inviteSnapshot.exists) {
          return {
            'eventId': eventId,
            ...eventData,
          };
        }
        return null;
      }).toList());

      setState(() {
        _events = filteredEvents.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  Future<void> applyToEvent(String eventId) async {
    final invitationRef = FirebaseDatabase.instance
        .ref()
        .child('invitations')
        .child(eventId)
        .child(artistId);

    final snapshot = await invitationRef.get();
    if (snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already applied to this event.")),
      );
      return;
    }

    await invitationRef.set({
      'artistName': artistName,
      'email': artistEmail,
      'appliedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Applied successfully! Status: Pending")),
    );

    fetchEvents(); // Refresh the list
  }

  String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply to Events")),
      body: _events.isEmpty
          ? const Center(child: Text("No available events to apply."))
          : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['bannerImageUrl'] != null &&
                    event['bannerImageUrl'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      event['bannerImageUrl'],
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
                        event['title'] ?? 'Untitled',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event['description'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(formatDate(event['eventDate'])),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text(event['time']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event['locationName'] ?? '')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          applyToEvent(event['eventId']);
                        },
                        child: const Text("Apply to Event"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
