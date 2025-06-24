import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref('adminreports');
  final DatabaseReference _interestCountRef = FirebaseDatabase.instance.ref('interestcount');
  final DatabaseReference _rsvpCountRef = FirebaseDatabase.instance.ref('rsvpcount');
  final DatabaseReference _bookingsRef = FirebaseDatabase.instance.ref('bookings');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final dataSnapshot = await _reportsRef.get();
    if (!dataSnapshot.exists) return;

    final Map<dynamic, dynamic> data = dataSnapshot.value as Map;
    final List<Map<String, dynamic>> temp = [];

    for (final entry in data.entries) {
      final eventId = entry.key;
      final report = entry.value as Map<dynamic, dynamic>;

      final String eventTitle = report['title'] ?? '';
      final String bannerImageUrl = report['bannerImageUrl'] ?? '';

      // Get interested count
      int interestedCount = 0;
      final interestSnapshot = await _interestCountRef.child(eventTitle).get();
      if (interestSnapshot.exists) {
        if (interestSnapshot.value is Map) {
          final interestData = interestSnapshot.value as Map<dynamic, dynamic>;
          interestedCount = interestData['interested'] is int
              ? interestData['interested']
              : int.tryParse(interestData['interested'].toString()) ?? 0;
        } else if (interestSnapshot.value is int) {
          interestedCount = interestSnapshot.value as int;
        }
      }

      // Get RSVP count
      int rsvpCount = 0;
      final rsvpSnapshot = await _rsvpCountRef.child(eventTitle).get();
      if (rsvpSnapshot.exists) {
        if (rsvpSnapshot.value is Map) {
          final rsvpData = rsvpSnapshot.value as Map<dynamic, dynamic>;
          rsvpCount = rsvpData['attending'] is int
              ? rsvpData['attending']
              : int.tryParse(rsvpData['attending'].toString()) ?? 0;
        } else if (rsvpSnapshot.value is int) {
          rsvpCount = rsvpSnapshot.value as int;
        }
      }

      // Get most liked artist from the adminreports node directly
      String mostLikedArtist = 'N/A';
      if (report.containsKey('mostLikedArtist') && report['mostLikedArtist'] is String) {
        final val = report['mostLikedArtist'] as String;
        if (val.trim().isNotEmpty) {
          mostLikedArtist = val;
        }
      }

      // Get confirmed visitors names from bookings + users
      Set<String> confirmedVisitorNames = {};
      final bookingsSnapshot = await _bookingsRef.get();
      if (bookingsSnapshot.exists) {
        final bookingsData = bookingsSnapshot.value as Map<dynamic, dynamic>;
        for (final bookingEntry in bookingsData.entries) {
          final booking = bookingEntry.value as Map<dynamic, dynamic>;
          if (booking['event'] != null && booking['event']['title'] == eventTitle) {
            final userId = booking['userId'];
            if (userId != null) {
              final userSnapshot = await _usersRef.child(userId).get();
              String name = 'Unknown User';
              if (userSnapshot.exists) {
                final userData = userSnapshot.value as Map<dynamic, dynamic>;
                if (userData.containsKey('fullName') &&
                    userData['fullName'].toString().trim().isNotEmpty) {
                  name = userData['fullName'].toString();
                } else if (userData.containsKey('email')) {
                  name = userData['email'].toString();
                }
              }
              confirmedVisitorNames.add(name);
            }
          }
        }
      }

      temp.add({
        'id': eventId,
        'title': eventTitle,
        'bannerImageUrl': bannerImageUrl,
        'interestedCount': interestedCount,
        'rsvpCount': rsvpCount,
        'mostLikedArtist': mostLikedArtist,
        'confirmedVisitors': confirmedVisitorNames.toList(),
      });
    }

    setState(() {
      reports = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Reports')),
      body: reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report['bannerImageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        report['bannerImageUrl'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    report['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Interested: ${report['interestedCount']}"),
                  Text("RSVP Count: ${report['rsvpCount']}"),
                  Text("Most Liked Artist: ${report['mostLikedArtist']}"),
                  const SizedBox(height: 10),
                  const Text("Confirmed Visitors:"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.from(
                      report['confirmedVisitors']
                          .map<Widget>((name) => Text("• $name")),
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