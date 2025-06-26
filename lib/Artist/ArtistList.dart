import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ArtistListPage extends StatefulWidget {
  final String eventId;
  const ArtistListPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<ArtistListPage> createState() => _ArtistListPageState();
}

class _ArtistListPageState extends State<ArtistListPage> {
  List<Map<String, dynamic>> _artists = [];
  Map<String, dynamic>? _eventData;

  @override
  void initState() {
    super.initState();
    fetchEventDataAndArtists();
  }

  Future<void> fetchEventDataAndArtists() async {
    final invitationsRef = FirebaseDatabase.instance.ref('invitations');
    final eventsRef = FirebaseDatabase.instance.ref('events');

    // Fetch event data
    final eventSnapshot = await eventsRef.child(widget.eventId).get();
    if (eventSnapshot.exists) {
      setState(() {
        _eventData = Map<String, dynamic>.from(eventSnapshot.value as Map);
      });
    }

    // Fetch artists for the event
    final inviteSnapshot = await invitationsRef.child(widget.eventId).get();

    if (inviteSnapshot.exists) {
      final inviteData = Map<String, dynamic>.from(inviteSnapshot.value as Map);
      List<Map<String, dynamic>> tempList = [];

      inviteData.forEach((artistId, artistData) {
        if (artistData is Map && artistData['status'] == 'accepted') {
          tempList.add({
            'artistId': artistId,
            'artistName': artistData['artistName'] ?? '',
          });
        }
      });

      setState(() {
        _artists = tempList;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Official Artist List")),
      body: _eventData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check if bannerImageUrl is not null or empty before rendering the image
            if (_eventData != null &&
                _eventData!['bannerImageUrl'] != null &&
                _eventData!['bannerImageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  _eventData!['bannerImageUrl'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    _eventData?['title'] ?? 'Event Title',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Event Description
                  Text(
                    _eventData?['description'] ?? 'No event description available.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Event Date and Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 6),
                      Text(_eventData?['eventDate'] != null
                          ? DateTime.fromMillisecondsSinceEpoch(_eventData!['eventDate']).toString()
                          : 'No Date Available'),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 6),
                      Text(_eventData?['time'] ?? 'No Time Available'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Event Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_eventData?['location'] ?? 'No Location Available')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Official Artist List Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Official Artist List",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // If no artists found
            if (_artists.isEmpty)
              const Center(child: Text("No artists found for this event."))
            else
            // List of Artist Names
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _artists.length,
                itemBuilder: (context, index) {
                  final artist = _artists[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Artist Name Only
                          Text(
                            artist['artistName'] ?? 'Unknown Artist',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
