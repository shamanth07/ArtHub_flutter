import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:art_hub/Artist/Arhome.dart';
import 'package:art_hub/Visitor/SignUp.dart';
import 'package:art_hub/Admin/AdLogin.dart';
import 'package:art_hub/Visitor/LogIn.dart';
import 'package:art_hub/Artist/ArLogin.dart';
import 'package:art_hub/Artist/ArSignUp.dart';

class ArSigninPage extends StatefulWidget {
  const ArSigninPage({super.key});

  @override
  State<ArSigninPage> createState() => _ArSigninPageState();
}

class _ArSigninPageState extends State<ArSigninPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isAgreed = false;
  String _selectedRole = 'Artist';
  final List<String> _roles = ['Visitor', 'Artist', 'Admin'];

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _navigateToRolePage(String role) {
    Widget targetPage;

    switch (role) {
      case 'Visitor':
        targetPage = SigninPage();
        break;
      case 'Artist':
        targetPage = ArSignupPage();
        break;
      case 'Admin':
        targetPage = AdSignUpPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (!_isAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must agree to the terms to continue')),
        );
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user!.uid;
        final userRef = FirebaseDatabase.instance.ref().child('users').child(uid);

        await userRef.set({
          'email': email,
          'role': 'Artist',
            // Save password in database
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ArHomePage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'email-already-in-use') {
          errorMessage = 'The email is already registered.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak.';
        } else {
          errorMessage = 'Sign up failed: ${e.message}';
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        onChanged: (bool? newValue) {
                          setState(() => _isAgreed = newValue ?? false);
                        },
                        activeColor: Colors.red,
                      ),
                      const Text("I agree to the ", style: TextStyle(fontSize: 13)),
                      const Text("Terms of Service", style: TextStyle(color: Colors.red, fontSize: 13)),
                      const Text(" & ", style: TextStyle(fontSize: 13)),
                      const Text("Privacy Policy", style: TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 30),
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
                      ),
                      child: const Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ArSignupPage()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(text: "Sign In", style: TextStyle(color: Colors.red)),
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
