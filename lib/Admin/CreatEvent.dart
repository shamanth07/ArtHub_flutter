import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

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

  DateTime? selectedDate;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  // Method to pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  // Method to create event
  void createEvent() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        maxVisitorsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final ref = FirebaseDatabase.instance.ref("events");
    final newEventRef = ref.push();

    final int maxArtists = int.tryParse(maxVisitorsController.text) ?? 0;

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
      "bannerImageUrl": _pickedImage != null
          ? _pickedImage!.path
          : "https://your-default-banner-url.jpg",
    };

    await newEventRef.set(eventData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Event created successfully")),
    );

    // Optionally clear form
    titleController.clear();
    descriptionController.clear();
    dateController.clear();
    timeController.clear();
    maxVisitorsController.clear();
    locationController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Event"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image (either picked or placeholder)
            GestureDetector(
              onTap: pickImage, // Open gallery on tap
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  image: DecorationImage(
                    image: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : AssetImage('assets/images/art_placeholder.jpg')
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            TextField(
              controller: titleController,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Enter Title",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      hintText: "Date",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onTap: () async {
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
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                      hintText: "Time",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onTap: () async {
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
            SizedBox(height: 10),

            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: Icon(Icons.location_pin, size: 40)),
            ),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: "Enter Event Location",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    print("Searching location: ${locationController.text}");
                  },
                  child: Text("Search"),
                ),
              ],
            ),
            SizedBox(height: 10),

            TextField(
              controller: maxVisitorsController,
              decoration: InputDecoration(
                hintText: "Maximum Artists Allowed",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: Text("Create"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
