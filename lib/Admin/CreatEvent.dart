import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path; // prefix added here

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
  bool isUploading = false;

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
      final fileName = path.basename(image.path);  // updated usage here
      final storageRef =
      FirebaseStorage.instance.ref().child('event_banners/$fileName');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  void createEvent() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        maxVisitorsController.text.isEmpty) {
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
      "bannerImageUrl": imageUrl,
      "location": locationController.text,
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
    locationController.clear();

    setState(() {
      _pickedImage = null;
      isUploading = false;
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
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Enter Title",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            const SizedBox(height: 10),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.lightGreen.shade50,
                image: const DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(child: Icon(Icons.location_pin, size: 40)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      hintText: "Enter Event Location",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    print("Searching location: ${locationController.text}");
                  },
                  child: const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxVisitorsController,
              decoration: const InputDecoration(
                hintText: "Maximum Artists Allowed",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
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
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text("Create"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
