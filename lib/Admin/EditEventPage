import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class EditEventPage extends StatefulWidget {
  final String eventKey;
  final Map<dynamic, dynamic> eventData;

  const EditEventPage({
    Key? key,
    required this.eventKey,
    required this.eventData,
  }) : super(key: key);

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController maxArtistsController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController ticketPriceController;

  DateTime? selectedDate;
  File? _pickedImage;
  String? bannerImageUrl;
  LatLng? selectedLatLng;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeControllers();
    bannerImageUrl = widget.eventData['bannerImageUrl'];
    _initializeMapLocationFromAddress();
  }

  void _initializeControllers() {
    titleController = TextEditingController(text: widget.eventData['title'] ?? '');
    descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    maxArtistsController = TextEditingController(text: widget.eventData['maxArtists']?.toString() ?? '');

    final eventDateMillis = widget.eventData['eventDate'];
    if (eventDateMillis != null && eventDateMillis is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(eventDateMillis);
      selectedDate = dt;
      dateController = TextEditingController(text: "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}");
    } else {
      dateController = TextEditingController();
    }

    timeController = TextEditingController(text: widget.eventData['time'] ?? '');
    locationController = TextEditingController(text: widget.eventData['location'] ?? '');

    // Initialize ticketPrice controller with the existing value or empty string
    ticketPriceController = TextEditingController(
      text: widget.eventData['ticketPrice'] != null ? widget.eventData['ticketPrice'].toString() : '',
    );
  }

  Future<void> _initializeMapLocationFromAddress() async {
    final address = widget.eventData['location'];
    if (address != null && address is String && address.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          setState(() {
            selectedLatLng = LatLng(loc.latitude, loc.longitude);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.move(selectedLatLng!, 13);
          });
        }
      } catch (_) {}
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        bannerImageUrl = picked.path;
      });
    }
  }

  Future<void> updateEvent() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        maxArtistsController.text.isEmpty ||
        ticketPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final int maxArtists = int.tryParse(maxArtistsController.text) ?? 0;
    final DateTime date = selectedDate ?? DateTime.tryParse(dateController.text) ?? DateTime.now();
    final double ticketPrice = double.tryParse(ticketPriceController.text) ?? 0.0;

    final eventData = {
      "eventId": widget.eventKey,
      "title": titleController.text,
      "description": descriptionController.text,
      "eventDate": date.millisecondsSinceEpoch,
      "time": timeController.text,
      "maxArtists": maxArtists,
      "ticketPrice": ticketPrice,
      "bannerImageUrl": bannerImageUrl ?? "https://your-default-banner-url.jpg",
      "location": locationController.text,
      "latitude": selectedLatLng?.latitude ?? widget.eventData['latitude'],
      "longitude": selectedLatLng?.longitude ?? widget.eventData['longitude'],
    };

    try {
      final ref = FirebaseDatabase.instance.ref("events").child(widget.eventKey);
      await ref.update(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated successfully")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update event: $e")),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    maxArtistsController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    ticketPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  image: DecorationImage(
                    image: bannerImageUrl != null
                        ? (bannerImageUrl!.startsWith("http")
                        ? NetworkImage(bannerImageUrl!) as ImageProvider
                        : FileImage(File(bannerImageUrl!)))
                        : const AssetImage('assets/images/art_placeholder.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Enter Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      hintText: "Date",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      hintText: "Time",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          timeController.text = picked.format(context);
                        });
                      }
                    },
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      center: selectedLatLng ?? LatLng(51.5, -0.09),
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          if (selectedLatLng != null)
                            Marker(
                              width: 80,
                              height: 80,
                              point: selectedLatLng!,
                              builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          hintText: "Event Location",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      width: 100,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final query = locationController.text.trim();
                          if (query.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a location to search.")),
                            );
                            return;
                          }

                          try {
                            List<Location> locations = await locationFromAddress(query);
                            if (locations.isNotEmpty) {
                              final loc = locations.first;
                              setState(() {
                                selectedLatLng = LatLng(loc.latitude, loc.longitude);
                                mapController.move(selectedLatLng!, 15);
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Location not found.")),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error searching location: $e")),
                            );
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text("Search"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            TextField(
              controller: maxArtistsController,
              decoration: const InputDecoration(
                hintText: "Maximum Artists",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 10),

            TextField(
              controller: ticketPriceController,
              decoration: const InputDecoration(
                hintText: "Ticket Price",
                border: OutlineInputBorder(),
                prefixText: "\$ ",
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: updateEvent,
                child: const Text(
                  "Update Event",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
