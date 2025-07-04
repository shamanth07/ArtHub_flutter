import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class UploadArtworkPage extends StatefulWidget {
  const UploadArtworkPage({super.key});

  @override
  State<UploadArtworkPage> createState() => _UploadArtworkPageState();
}

class _UploadArtworkPageState extends State<UploadArtworkPage> {
  File? _image;
  final picker = ImagePicker();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final yearController = TextEditingController();
  final priceController = TextEditingController();

  bool _isUploading = false;

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> saveArtwork() async {
    if (_image == null ||
        titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty ||
        yearController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upload artwork')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final artworkId = const Uuid().v4();

      final storageRef =
      FirebaseStorage.instance.ref().child('artwork_images/$artworkId.jpg');
      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      final artworkData = {
        "id": artworkId,
        "artistId": user.uid,
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "category": categoryController.text.trim(),
        "year": yearController.text.trim(),
        "price": priceController.text.trim(),
        "imageUrl": imageUrl,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "likes": 0, // initialize likes
      };

      final db = FirebaseDatabase.instance.ref();

      await db.update({
        'artworks/$artworkId': artworkData,
        'artists/${user.uid}/artworks/$artworkId': artworkData,
      });

      // Initialize empty comments node
      await db.child('artworks/$artworkId/comments').set({});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork uploaded successfully')),
      );

      setState(() {
        _image = null;
        titleController.clear();
        descriptionController.clear();
        categoryController.clear();
        yearController.clear();
        priceController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Artwork'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey),
                ),
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Center(child: Text('Tap to select image')),
              ),
            ),
            const SizedBox(height: 20),
            buildTextField("Title", titleController),
            buildTextField("Description", descriptionController, maxLines: 3),
            buildTextField("Category", categoryController),
            buildTextField("Year Created", yearController,
                keyboardType: TextInputType.number),
            buildTextField("Price", priceController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            _isUploading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: saveArtwork,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: (label == "Year Created" || label == "Price")
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
      ),
    );
  }
}
