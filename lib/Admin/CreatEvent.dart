import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxVisitorsController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController ticketPriceController = TextEditingController(); // ✅ New controller

  DateTime? selectedDate;
  File? _pickedImage;
  bool isUploading = false;

  // For map and location search
  late MapController _mapController;
  LatLng _currentLatLng = LatLng(20.5937, 78.9629); // Default center India

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      final fileName = path.basename(image.path);
      final storageRef =
      FirebaseStorage.instance.ref().child('event_banners/$fileName');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  Future<void> _handleSearch() async {
    String query = locationController.text.trim();
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);

        setState(() {
          _currentLatLng = newLatLng;
        });

        _mapController.move(newLatLng, 12);
      }
    } catch (e) {
      debugPrint("Error during geocoding: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Place not found")),
      );
    }
  }

  void createEvent() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        maxVisitorsController.text.isEmpty ||
        ticketPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    String imageUrl = "https://your-default-banner-url.jpg";
    if (_pickedImage != null) {
      final uploadedUrl = await uploadImage(_pickedImage!);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final ref = FirebaseDatabase.instance.ref("events");
    final newEventRef = ref.push();

    final int maxArtists = int.tryParse(maxVisitorsController.text) ?? 0;
    final double ticketPrice = double.tryParse(ticketPriceController.text) ?? 0;
    final DateTime date = selectedDate ??
        DateTime.tryParse(dateController.text) ??
        DateTime.now();

    final eventData = {
      "eventId": newEventRef.key,
      "title": titleController.text,
      "description": descriptionController.text,
      "eventDate": date.millisecondsSinceEpoch,
      "time": timeController.text,
      "maxArtists": maxArtists,
      "ticketPrice": ticketPrice, // ✅ Add ticketPrice to DB
      "bannerImageUrl": imageUrl,
      "location": locationController.text,
      "latitude": _currentLatLng.latitude,
      "longitude": _currentLatLng.longitude,
    };

    await newEventRef.set(eventData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event created successfully")),
    );

    // Clear form
    titleController.clear();
    descriptionController.clear();
    dateController.clear();
    timeController.clear();
    maxVisitorsController.clear();
    ticketPriceController.clear(); // ✅ Clear ticket price field
    locationController.clear();

    setState(() {
      _pickedImage = null;
      isUploading = false;
      _currentLatLng = LatLng(20.5937, 78.9629); // Reset map center
      _mapController.move(_currentLatLng, 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
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
                    image: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : const AssetImage('assets/images/art_placeholder.jpg')
                    as ImageProvider,
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
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Enter Title",
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      hintText: "Date",
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        dateController.text =
                        "${picked.year}-${picked.month}-${picked.day}";
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
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        timeController.text = picked.format(context);
                      }
                    },
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        hintText: "Enter Location",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSearch,
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentLatLng,
                  zoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLatLng,
                        width: 40,
                        height: 40,
                        builder: (context) => const Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maxVisitorsController,
              decoration: const InputDecoration(
                hintText: "Maximum Artists Allowed",
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 8),

            // ✅ Ticket Price Field
            TextField(
              controller: ticketPriceController,
              decoration: const InputDecoration(
                hintText: "Ticket Price",
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 8),
            Center(
              child: isUploading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Create Event"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}