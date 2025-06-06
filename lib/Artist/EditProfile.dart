import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditArtistProfilePage extends StatefulWidget {
  const EditArtistProfilePage({super.key});

  @override
  State<EditArtistProfilePage> createState() => _EditArtistProfilePageState();
}

class _EditArtistProfilePageState extends State<EditArtistProfilePage> {
  final database = FirebaseDatabase.instance.ref();
  final storage = FirebaseStorage.instance;
  final user = FirebaseAuth.instance.currentUser;

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final websiteController = TextEditingController();
  final instagramController = TextEditingController();

  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    if (user == null) return;
    final snapshot = await database.child('artists/${user!.uid}').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nameController.text = data['name'] ?? '';
        bioController.text = data['bio'] ?? '';
        websiteController.text = data['socialLinks']?['website'] ?? '';
        instagramController.text = data['socialLinks']?['instagram'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(File file) async {
    final path = 'profile_images/${user!.uid}.jpg';
    final ref = storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    String? imageUrl = _profileImageUrl;

    // If a new image is selected, upload it
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
    }

    await database.child('artists/${user!.uid}').update({
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
      'profileImageUrl': imageUrl,
      'socialLinks': {
        'website': websiteController.text.trim(),
        'instagram': instagramController.text.trim(),
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage("assets/placeholder.png")) as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instagramController,
              decoration: const InputDecoration(labelText: 'Instagram'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
