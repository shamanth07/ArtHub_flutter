import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Artist/ArtistList.dart'; // adjust the path as needed

class BookEventPage extends StatefulWidget {
  final String eventId;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final double ticketPrice;
  final String date;
  final String time;

  const BookEventPage({
    super.key,
    required this.eventId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.ticketPrice,
    required this.date,
    required this.time,
  });

  @override
  State<BookEventPage> createState() => _BookEventPageState();
}

class _BookEventPageState extends State<BookEventPage> {
  int _ticketCount = 1;
  static const double _taxRate = 0.18;
  Map<String, int> likedArtistsCount = {}; // artistUid -> like count
  Set<String> likedArtists = {}; // locally liked artist UIDs

  double get _subtotal => widget.ticketPrice * _ticketCount;
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? paymentIntent;
  bool? _isAttending;
  bool _isLoadingRSVP = false;

  // Correct: Single declaration as List of Map<String, String>
  List<Map<String, String>> invitedArtists = [];

  @override
  void initState() {
    super.initState();
    _fetchRSVPStatus();
    fetchUserLikedArtists();
    fetchLikeCounts();
    fetchAcceptedArtists();
  }

  Future<void> fetchAcceptedArtists() async {
    final snapshot = await _database.child('invitations/${widget.eventId}').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, String>> temp = [];
      data.forEach((artistUid, details) {
        if (details is Map && details['status'] == 'accepted') {
          final name = details['artistName'];
          if (name != null) {
            temp.add({'uid': artistUid.toString(), 'name': name.toString()});
          }
        }
      });
      setState(() {
        invitedArtists = temp;
      });
    }
  }

  void fetchUserLikedArtists() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userId = user.uid;
    final ref = _database.child('artistLikesInEvents/${widget.eventId}');
    final snapshot = await ref.get();
    Set<String> liked = {};
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((artistUid, artistData) {
        if (artistData is Map && artistData[userId] == true) {
          liked.add(artistUid.toString());
        }
      });
    }
    setState(() {
      likedArtists = liked;
    });
  }

  void toggleLike(String artistUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userId = user.uid;
    final eventId = widget.eventId;

    final userLikeRef = _database.child('artistLikesInEvents/$eventId/$artistUid/$userId');
    final countRef = _database.child('artistlikescount/$eventId/$artistUid');

    final hasLiked = likedArtists.contains(artistUid);

    setState(() {
      if (hasLiked) {
        likedArtists.remove(artistUid);
      } else {
        likedArtists.add(artistUid);
      }
    });

    if (hasLiked) {
      await userLikeRef.remove();
    } else {
      await userLikeRef.set(true);
    }

    await countRef.runTransaction((currentData) {
      int current = 0;
      if (currentData is int) {
        current = currentData;
      } else if (currentData is String) {
        current = int.tryParse(currentData) ?? 0;
      }
      int updatedCount;
      if (hasLiked) {
        updatedCount = (current - 1) < 0 ? 0 : (current - 1);
      } else {
        updatedCount = current + 1;
      }
      return Transaction.success(updatedCount);
    });
  }

  Future<void> _fetchRSVPStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final rsvpRef = _database.child('eventinterest/${widget.title}/${user.uid}');
    final snapshot = await rsvpRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final status = data['interested'];
      if (status != null) {
        setState(() {
          _isAttending = status;
        });
      }
    }
  }

  void fetchLikeCounts() {
    final countRef = _database.child('artistlikescount/${widget.eventId}');
    countRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        Map<String, int> counts = {};
        data.forEach((artistUid, value) {
          counts[artistUid.toString()] = int.tryParse(value.toString()) ?? 0;
        });
        setState(() {
          likedArtistsCount = counts;
        });
      }
    });
  }

  void _incrementTickets() {
    setState(() {
      _ticketCount++;
    });
  }

  void _decrementTickets() {
    if (_ticketCount > 1) {
      setState(() {
        _ticketCount--;
      });
    }
  }

  Future<void> _markRSVP(bool attending) async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() {
      _isLoadingRSVP = true;
    });
    final rsvpRef = _database.child('eventinterest/${widget.title}/${user.uid}');
    final countRef = _database.child('interestcount/${widget.title}/interested');
    await rsvpRef.update({'interested': attending});
    final snapshot = await countRef.get();

    int currentCount = 0;
    if (snapshot.exists) {
      if (snapshot.value is int) {
        currentCount = snapshot.value as int;
      } else if (snapshot.value is Map) {
        // Defensive fallback if count stored in Map
        final mapVal = snapshot.value as Map<dynamic, dynamic>;
        currentCount = mapVal['interested'] ?? 0;
      } else if (snapshot.value is String) {
        currentCount = int.tryParse(snapshot.value.toString()) ?? 0;
      }
    }

    if (attending) {
      await countRef.set(currentCount + 1);
    } else {
      if (currentCount > 0) {
        await countRef.set(currentCount - 1);
      }
    }

    setState(() {
      _isAttending = attending;
      _isLoadingRSVP = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked as ${attending ? "interested" : "Not interested"}')),
    );
  }

  Future<void> _bookEvent() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to book an event.")),
        );
        return;
      }

      final eventDate = DateTime.tryParse(widget.date);
      if (eventDate == null || eventDate.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid or past event date.")),
        );
        return;
      }

      paymentIntent = await createPaymentIntent(_total.toStringAsFixed(2), "cad");
      if (paymentIntent == null || paymentIntent!['client_secret'] == null) {
        throw Exception('Failed to create PaymentIntent');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          merchantDisplayName: 'ArtHub Event',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final bookingRef = _database.child('bookings').push();
      await bookingRef.set({
        'userId': user.uid,
        'event': {
          'title': widget.title,
          'description': widget.description,
          'imageUrl': widget.imageUrl,
          'location': widget.location,
          'ticketPrice': widget.ticketPrice,
          'date': widget.date,
          'time': widget.time,
        },
        'ticketsBooked': _ticketCount,
        'subtotal': _subtotal,
        'tax': _tax,
        'total': _total,
        'bookingTimestamp': DateTime.now().toIso8601String(),
        'paymentStatus': 'Success',
      });

      final rsvpRef = _database.child('rsvp/${widget.title}/${user.uid}');
      final rsvpCountRef = _database.child('rsvpcount/${widget.title}');

      await rsvpRef.update({'tickets': _ticketCount});

      final countSnapshot = await rsvpCountRef.get();
      int currentTotal = 0;
      if (countSnapshot.exists) {
        final data = countSnapshot.value;
        if (data is Map<dynamic, dynamic>) {
          currentTotal = data['attending'] ?? 0;
        } else if (data is int) {
          currentTotal = data;
        }
      }

      int updatedTotal = currentTotal + _ticketCount;

      await rsvpCountRef.set({'attending': updatedTotal});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking successful! Total: ₹${_total.toStringAsFixed(2)}"),
        ),
      );

      paymentIntent = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e")),
      );
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(String amount, String currency) async {
    try {
      int amountInCents = (double.parse(amount) * 100).toInt();

      final Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      const String secretKey =
          'sk_test_51QZiSj026qNc6iTx7wy3YLmHjBP5NH3oZKsTDT7yMUbDYIeqRlie0B4rAI02pqDtPnm9UvVL0X9uqZJKJHJR7z4r00MNHSvf6J';

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (err) {
      print('Error creating payment intent: $err');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Details"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("📍 ${widget.location}", style: const TextStyle(fontSize: 16)),
            Text("🗓️ ${widget.date} at ${widget.time}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(widget.description, style: const TextStyle(fontSize: 16)),

            if (invitedArtists.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "🎨 Invited Artists:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...invitedArtists.map((artistMap) {
                final artistUid = artistMap['uid']!;
                final artistName = artistMap['name']!;
                final isLiked = likedArtists.contains(artistUid);
                final likeCount = likedArtistsCount[artistUid] ?? 0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => toggleLike(artistUid),
                  ),
                  title: Text(artistName, style: const TextStyle(fontSize: 16)),
                  trailing: Text(
                    likeCount.toString(),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Tickets:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _decrementTickets,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: _ticketCount > 1 ? Colors.black : Colors.grey,
                ),
                Text('$_ticketCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _incrementTickets,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.black,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_isLoadingRSVP || _isAttending == true) ? null : () => _markRSVP(true),
                  icon: const Icon(Icons.check),
                  label: const Text("Interested"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.green.shade200,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: (_isLoadingRSVP || _isAttending == false) ? null : () => _markRSVP(false),
                  icon: const Icon(Icons.close),
                  label: const Text("Not Interested"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade200,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text("Subtotal: ₹${_subtotal.toStringAsFixed(2)}"),
            Text("Tax (18%): ₹${_tax.toStringAsFixed(2)}"),
            Text("Total: ₹${_total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _bookEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Pay Now"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
