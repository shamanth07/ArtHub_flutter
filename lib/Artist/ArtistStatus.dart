
// application_status_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({super.key});

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  String artistId = '';
  List<Map<String, dynamic>> _appliedEvents = [];

  @override
  void initState() {
    super.initState();
    initializeUserData();
  }

  Future<void> initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      artistId = user.uid;
      fetchAppliedEvents();
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
        // artistMap should be a Map
        if (artistMap is Map) {
          final artists = Map<String, dynamic>.from(artistMap);

          // Check if this artist applied
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
                      )
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
