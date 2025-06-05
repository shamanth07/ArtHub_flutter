import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdForgetPassword extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdForgetPassword({super.key});

  void _sendResetEmail(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(context, "Please enter your email.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage(context, "Password reset link sent to $email. Please check your email.");
    } on FirebaseAuthException catch (e) {
      _showMessage(context, "Error: ${e.message}");
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Message"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Forgot Password",
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 60),

              Align(
                alignment: Alignment.center,
                child: Text(
                  "Email:",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Enter your Email here....",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              SizedBox(height: 50),

              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    _sendResetEmail(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white70,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text("Send Email"),
                ),
              ),
              SizedBox(height: 40),

              SizedBox(
                width: 160,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white70,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text("Back To Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
