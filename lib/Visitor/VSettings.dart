import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newarthub/Visitor/ChatPage.dart';
import 'package:newarthub/Visitor/ThemeProvider.dart';// adjust path as needed

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Logo + Title
              Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 32),
                      Text(
                        "ARTHUB",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.settings, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  "Settings",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 50),

              // Dark Mode Toggle
              Row(
                children: [
                  const Icon(Icons.dark_mode, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Dark Mode",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 1),
              const SizedBox(height: 40),

              // Change Language
              Row(
                children: const [
                  Icon(Icons.g_translate, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Change Language",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 1),
              const SizedBox(height: 40),

              // Live Chat Support
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserChatPage(
                        userId: FirebaseAuth.instance.currentUser!.uid,
                        userRole: "visitor",
                      ),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Icon(Icons.headset_mic, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Live Chat Support",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Divider(thickness: 1),
            ],
          ),
        ),
      ),
    );
  }
}
