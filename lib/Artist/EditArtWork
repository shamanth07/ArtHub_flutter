import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

class EditArtworkPage extends StatefulWidget {
  final String artworkId;
  final String title;
  final String imageUrl;

  const EditArtworkPage({
    Key? key,
    required this.artworkId,
    required this.title,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<EditArtworkPage> createState() => _EditArtworkPageState();
}

class _EditArtworkPageState extends State<EditArtworkPage> {
  File? _image;
  final picker = ImagePicker();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? existingImageUrl;
  String? artistId;

  @override
  void initState() {
    super.initState();
    loadArtworkData();
  }

  Future<void> loadArtworkData() async {
    final snapshot = await FirebaseDatabase.instance.ref('artworks/${widget.artworkId}').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        artistId = data['artistId'];
        titleController.text = data['title'] ?? '';
        descriptionController.text = data['description'] ?? '';
        categoryController.text = data['category'] ?? '';
        yearController.text = data['year'] ?? '';
        priceController.text = data['price'] ?? '';
        existingImageUrl = data['imageUrl'];
        _isLoading = false;
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> updateArtwork() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty ||
        yearController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      String imageUrl = existingImageUrl ?? '';
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('artwork_images/${widget.artworkId}.jpg');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updatedArtwork = {
        "id": widget.artworkId,
        "artistId": artistId,
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "category": categoryController.text.trim(),
        "year": yearController.text.trim(),
        "price": priceController.text.trim(),
        "imageUrl": imageUrl,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      final db = FirebaseDatabase.instance.ref();
      await db.update({
        'artworks/${widget.artworkId}': updatedArtwork,
        'artists/$artistId/artworks/${widget.artworkId}': updatedArtwork,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Widget buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Artwork'),
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
                    : (existingImageUrl != null
                    ? Image.network(existingImageUrl!, fit: BoxFit.cover)
                    : const Center(child: Text('Tap to select image'))),
              ),
            ),
            const SizedBox(height: 20),
            buildTextField("Title", titleController),
            buildTextField("Description", descriptionController),
            buildTextField("Category", categoryController),
            buildTextField(
              "Year Created",
              yearController,
              type: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            buildTextField(
              "Price",
              priceController,
              type: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            _isUpdating
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: updateArtwork,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white60,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Update Artwork'),
            ),
          ],
        ),
      ),
    );
  }
}

