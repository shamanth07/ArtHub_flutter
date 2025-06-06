import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newarthub/Visitor/LogIn.dart';
import 'package:newarthub/Artist/ArSignUp.dart';
import 'package:newarthub/Admin/AdLogin.dart';

import 'package:newarthub/Visitor/Vhome.dart';
import 'package:newarthub/Artist/ArLogin.dart';
import 'package:newarthub/Visitor/SignUp.dart';
class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isAgreed = false;
  String _selectedRole = 'Visitor';
  final List<String> _roles = ['Visitor', 'Artist', 'Admin'];

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _navigateToRolePage(String role) {
    switch (role) {
      case 'Visitor':
        return; // Stay on the same page
      case 'Artist':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ArSignupPage()),
        );
        break;
      case 'Admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdSignUpPage()),
        );
        break;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final role = _selectedRole;

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;

        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$uid');

        DatabaseEvent snapshot = await userRef.once();
        if (!snapshot.snapshot.exists) {
          await userRef.set({
            'email': email,
            'role': role,
            
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully.")),
          );
        } else {
          await userRef.update({'role': role});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account updated successfully.")),
          );
        }

        // Navigate to Home Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  VisitorHomePage()),
        );
      } on FirebaseAuthException catch (e) {
        String error = "Sign-up failed.";
        if (e.code == 'email-already-in-use') error = "Email already in use.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/arthub_logo.png', height: 200),
                  const SizedBox(height: 10),

                  // Role Dropdown
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 40,
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role, style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedRole) {
                            _navigateToRolePage(value);
                          }
                        },
                        style: const TextStyle(color: Colors.black87),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Email',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: "example@email.com",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter your email";
                      if (!value.contains('@')) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "******",
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) =>
                    value!.length < 6 ? "Password must be at least 6 characters" : null,
                  ),
                  const SizedBox(height: 20),

                  // Terms Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        onChanged: (bool? newValue) {
                          setState(() => _isAgreed = newValue!);
                        },
                        activeColor: Colors.red,
                      ),
                      const Text(
                        "I agree to the ",
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                      const Text(
                        "Terms of Service",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const Text(
                        " & ",
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                      const Text(
                        "Privacy Policy",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAgreed ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account link
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dummy HomePage for navigation
