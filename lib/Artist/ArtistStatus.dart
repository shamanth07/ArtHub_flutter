// application_status_page.dart (Updated)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'ArtistList.dart'; // Import ArtistListPage

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({super.key});

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  String artistId = '';
  List<Map<String, dynamic>> _appliedEvents = [];
  Map<String, int> _rsvpCounts = {};

  @override
  void initState() {
    super.initState();
    initializeUserData();
  }

  Future<void> initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      artistId = user.uid;
      await fetchAppliedEvents();
      await fetchRSVPCounts();
    }
  }

  Future<void> fetchAppliedEvents() async {
    final invitationsRef = FirebaseDatabase.instance.ref('invitations');
    final eventsRef = FirebaseDatabase.instance.ref('events');

    final inviteSnapshot = await invitationsRef.get();
    final eventsSnapshot = await eventsRef.get();

    if (inviteSnapshot.exists && eventsSnapshot.exists) {
      final inviteData = Map<String, dynamic>.from(inviteSnapshot.value as Map);
      final eventsData = Map<String, dynamic>.from(eventsSnapshot.value as Map);

      List<Map<String, dynamic>> tempList = [];

      inviteData.forEach((eventId, artistMap) {
        if (artistMap is Map) {
          final artists = Map<String, dynamic>.from(artistMap);

          if (artists.containsKey(artistId)) {
            final artistEntry = artists[artistId];

            if (artistEntry is Map && eventsData[eventId] is Map) {
              final statusData = Map<String, dynamic>.from(artistEntry);
              final eventData = Map<String, dynamic>.from(eventsData[eventId]);

              tempList.add({
                'eventId': eventId,
                ...eventData,
                'status': statusData['status'] ?? 'pending',
              });
            }
          }
        }
      });

      setState(() {
        _appliedEvents = tempList;
      });
    }
  }

  Future<void> fetchRSVPCounts() async {
    final counts = <String, int>{};

    for (var event in _appliedEvents) {
      final eventTitle = event['title'];
      if (eventTitle != null && eventTitle.toString().isNotEmpty) {
        final ref = FirebaseDatabase.instance.ref('rsvpcount/$eventTitle/attending');
        final snapshot = await ref.get();

        if (snapshot.exists) {
          counts[eventTitle] = snapshot.value as int;
        } else {
          counts[eventTitle] = 0;
        }
      }
    }

    setState(() {
      _rsvpCounts = counts;
    });
  }


  String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Application Status")),
      body: _appliedEvents.isEmpty
          ? const Center(child: Text("No applications found."))
          : ListView.builder(
        itemCount: _appliedEvents.length,
        itemBuilder: (context, index) {
          final event = _appliedEvents[index];
          final status = event['status'];
          final eventTitle = event['title'] ?? '';
          final eventId = event['eventId'];  // Get the eventId

          final rsvpCount = _rsvpCounts[eventTitle] ?? 0;

          return GestureDetector(
            onTap: () {
              // Navigate to the artist list page when the event is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistListPage(eventId: eventId),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event['bannerImageUrl'] != null && event['bannerImageUrl'].toString().isNotEmpty)
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
                          eventTitle,
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
                            Expanded(child: Text(event['location'] ?? '')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Status: ${status.toString().toUpperCase()}",
                          style: TextStyle(
                            color: status == 'accepted'
                                ? Colors.green
                                : status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RSVP Attending Count: $rsvpCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
