import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminInvitationsPage extends StatefulWidget {
  const AdminInvitationsPage({super.key});

  @override
  State<AdminInvitationsPage> createState() => _AdminInvitationsPageState();
}

class _AdminInvitationsPageState extends State<AdminInvitationsPage> {
  final DatabaseReference _invitationsRef = FirebaseDatabase.instance.ref('invitations');
  final DatabaseReference _eventsRef = FirebaseDatabase.instance.ref('events');

  List<Map<String, dynamic>> _allInvitations = [];

  @override
  void initState() {
    super.initState();
    fetchAllInvitations();
  }

  Future<void> fetchAllInvitations() async {
    final invitationSnapshot = await _invitationsRef.get();

    if (invitationSnapshot.exists) {
      final invitations = <Map<String, dynamic>>[];

      for (final eventEntry in invitationSnapshot.children) {
        final eventId = eventEntry.key!;
        final eventSnapshot = await _eventsRef.child(eventId).get();
        final eventTitle = eventSnapshot.child('title').value ?? 'Unknown Event';

        for (final artistEntry in eventEntry.children) {
          final artistId = artistEntry.key!;
          final data = Map<String, dynamic>.from(artistEntry.value as Map);

          invitations.add({
            'eventId': eventId,
            'eventTitle': eventTitle,
            'artistId': artistId,
            ...data,
          });
        }
      }

      setState(() {
        _allInvitations = invitations;
      });
    }
  }

  Future<void> updateStatus(String eventId, String artistId, String newStatus) async {
    await _invitationsRef.child(eventId).child(artistId).update({'status': newStatus});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invitation status updated to $newStatus.")),
    );

    fetchAllInvitations(); // refresh
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsRef.child(eventId).remove();
      await _invitationsRef.child(eventId).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event deleted successfully.")),
      );

      fetchAllInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete event: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Invitations")),
      body: _allInvitations.isEmpty
          ? const Center(child: Text("No invitations found."))
          : ListView.builder(
        itemCount: _allInvitations.length,
        itemBuilder: (context, index) {
          final invite = _allInvitations[index];
          final status = invite['status'] ?? 'pending';

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Event: ${invite['eventTitle']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Artist: ${invite['artistName']}"),
                  Text("Email: ${invite['email']}"),
                  Text("Status: ${status.toString().toUpperCase()}"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Accept"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: status == 'accepted'
                                ? null
                                : () => updateStatus(invite['eventId'], invite['artistId'], 'accepted'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: status == 'rejected'
                                ? null
                                : () => updateStatus(invite['eventId'], invite['artistId'], 'rejected'),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black54),
                        tooltip: 'Delete Event',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Event"),
                              content: const Text("Are you sure you want to delete this event and all its invitations?"),
                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    deleteEvent(invite['eventId']);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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