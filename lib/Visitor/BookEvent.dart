import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BookEventPage extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final double ticketPrice;
  final String date;
  final String time;

  const BookEventPage({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.ticketPrice,
    required this.date,
    required this.time,
  });

  @override
  _BookEventPageState createState() => _BookEventPageState();
}

class _BookEventPageState extends State<BookEventPage> {
  int _ticketCount = 1;
  static const double _taxRate = 0.18; // 18% tax

  double get _subtotal => widget.ticketPrice * _ticketCount;
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

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

  Future<void> _bookEvent() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        // Not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to book an event.")),
        );
        return;
      }

      // Parse event date - expects ISO 8601 format: YYYY-MM-DD or full ISO
      final eventDate = DateTime.tryParse(widget.date);
      final today = DateTime.now();

      if (eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid event date.")),
        );
        return;
      }

      // Compare only year, month, day - ignore time
      final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      if (eventDateOnly.isBefore(todayDateOnly)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This event is no longer available for booking.")),
        );
        return;
      }

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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Booking successful for $_ticketCount ticket${_ticketCount > 1 ? 's' : ''}!\nTotal: ₹${_total.toStringAsFixed(2)}",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              Text(
                widget.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "📍 Location: ${widget.location}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "📅 Date: ${widget.date} at ${widget.time}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Ticket quantity selector
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    "Tickets:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: _decrementTickets,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _ticketCount > 1 ? Colors.black : Colors.grey,
                    iconSize: 30,
                  ),
                  Text(
                    '$_ticketCount',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _incrementTickets,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.black,
                    iconSize: 30,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Price details
              Text(
                "Subtotal: ₹${_subtotal.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                "Tax (18%): ₹${_tax.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                "Total: ₹${_total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _bookEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Pay Now"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
