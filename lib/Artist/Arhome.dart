import 'package:flutter/material.dart';
class ArHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Artist Home")),
      body: const Center(child: Text("Welcome, Artist!")),
    );
  }
}