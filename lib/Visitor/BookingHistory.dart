import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final DatabaseReference _bookingRef =
  FirebaseDatabase.instance.ref().child('bookings');

  List<Map<String, dynamic>> _bookings = [];
  List<String> _bookingKeys = [];

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
  }

  Future<void> _loadBookingHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _bookings = [];
        _bookingKeys = [];
      });
      return;
    }

    final snapshot =
    await _bookingRef.orderByChild('userId').equalTo(user.uid).once();

    if (snapshot.snapshot.value == null) {
      setState(() {
        _bookings = [];
        _bookingKeys = [];
      });
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

    final bookings = <Map<String, dynamic>>[];
    final keys = <String>[];

    data.forEach((key, value) {
      final booking = Map<String, dynamic>.from(value);
      bookings.add(booking);
      keys.add(key);
    });

    bookings.sort((a, b) => b['bookingTimestamp']
        .toString()
        .compareTo(a['bookingTimestamp'].toString()));

    keys.sort((a, b) {
      final aTimestamp = bookings[bookings.indexWhere(
              (bkg) => bkg['bookingTimestamp'] == data[a]['bookingTimestamp'])]
      ['bookingTimestamp'];
      final bTimestamp = bookings[bookings.indexWhere(
              (bkg) => bkg['bookingTimestamp'] == data[b]['bookingTimestamp'])]
      ['bookingTimestamp'];
      return bTimestamp.toString().compareTo(aTimestamp.toString());
    });

    setState(() {
      _bookings = bookings;
      _bookingKeys = keys;
    });
  }

  Future<void> _cancelBooking(int index) async {
    final bookingKey = _bookingKeys[index];
    final booking = _bookings[index];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _bookingRef.child(bookingKey).remove();

      final int ticketsBooked = booking['ticketsBooked'] ?? 0;

      if (ticketsBooked > 0) {
        final eventTitle = booking['event']?['title'] ?? '';

        if (eventTitle.isNotEmpty) {
          final rsvpUserRef =
          FirebaseDatabase.instance.ref('rsvp/$eventTitle/${user.uid}');
          final rsvpCountRef =
          FirebaseDatabase.instance.ref('rsvpcount/$eventTitle/attending');

          final userRsvpSnapshot = await rsvpUserRef.get();
          if (userRsvpSnapshot.exists) {
            final userData = userRsvpSnapshot.value as Map<dynamic, dynamic>;
            int currentUserTickets = userData['tickets'] ?? 0;

            int updatedUserTickets = currentUserTickets - ticketsBooked;
            if (updatedUserTickets > 0) {
              await rsvpUserRef.update({'tickets': updatedUserTickets});
            } else {
              await rsvpUserRef.remove();
            }
          }

          final rsvpCountSnapshot = await rsvpCountRef.get();
          int currentTotal = 0;
          if (rsvpCountSnapshot.exists) {
            currentTotal = rsvpCountSnapshot.value as int;
          }

          int updatedTotal = currentTotal - ticketsBooked;
          if (updatedTotal < 0) updatedTotal = 0;

          await rsvpCountRef.set(updatedTotal);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking cancelled successfully.")),
      );

      setState(() {
        _bookings.removeAt(index);
        _bookingKeys.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel booking: $e")),
      );
    }
  }

  bool _isEventInFuture(String eventDate) {
    try {
      final eventDateTime = DateFormat('yyyy-MM-dd').parse(eventDate);
      final now = DateTime.now();
      return !eventDateTime.isBefore(DateTime(now.year, now.month, now.day));
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Booking History"),
          centerTitle: true,
        ),
        body: const Center(child: Text("No bookings found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Booking History"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          final event = booking['event'] ?? {};

          final title = event['title'] ?? 'No Title';
          final location = event['location'] ?? 'Unknown';
          final date = event['date'] ?? 'Unknown Date';
          final time = event['time'] ?? 'Unknown Time';

          final ticketsBooked = booking['ticketsBooked'] ?? 0;
          final subtotal = booking['subtotal'] ?? 0.0;
          final tax = booking['tax'] ?? 0.0;
          final total = booking['total'] ?? 0.0;

          final timestampStr = booking['bookingTimestamp'] ?? '';
          final formattedTimestamp = timestampStr
              .toString()
              .replaceFirst('T', ' ')
              .split('.')
              .first;

          final canCancel = _isEventInFuture(date);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("📍 $location"),
                  Text("📅 $date at $time"),
                  const SizedBox(height: 4),
                  Text("Tickets: $ticketsBooked"),
                  Text("Subtotal: ₹${subtotal.toStringAsFixed(2)}"),
                  Text("Tax: ₹${tax.toStringAsFixed(2)}"),
                  Text("Total: ₹${total.toStringAsFixed(2)}"),
                  const SizedBox(height: 4),
                  Text(
                    "Booked on: $formattedTimestamp",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (canCancel)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Booking'),
                              content: const Text(
                                  'Are you sure you want to cancel this booking?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _cancelBooking(index);
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel Booking'),
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
