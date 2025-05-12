import 'package:flutter/material.dart';


class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

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
              // Title
              Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 60),

              // Email label
              Align(
                alignment: Alignment.center,
                child: Text(
                  "Email:",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Email TextField
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

              // Send Email button
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement send reset email logic
                    print("Reset link sent to: ${emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
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

              // Back To Login button
              SizedBox(
                width: 160,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to Login screen
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey,
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
