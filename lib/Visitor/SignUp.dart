import 'package:flutter/material.dart';
import 'package:art_hub/Visitor/LogIn.dart';

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
  bool _isAgreed = false; // Checkbox value
  String _selectedRole = 'Visitor';
  final List<String> _roles = ['Visitor', 'Artist', 'Admin'];

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final role = _selectedRole;

      print("Email: $email | Password: $password | Role: $role");
      // Add Firebase or backend signup logic here
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
                  Image.asset(
                    'assets/images/arthub_logo.png',
                    height: 200,
                  ),
                  const SizedBox(height: 10),

                  /// 👇 Role Dropdown (Right-aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
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
                        items: _roles
                            .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        style: const TextStyle(color: Colors.black87),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 👇 Email Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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

                  /// 👇 Password Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "*******",
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

                  /// 👇 Checkbox: I agree to the terms and privacy policy (Horizontal)
                  Row(
                    children: [
                      Checkbox(

                        value: _isAgreed,

                        onChanged: (bool? newValue) {
                          setState(() {
                            _isAgreed = newValue!;

                          });
                        },
                        activeColor: Colors.red,
                      ),
                      const Text(
                        "I agree to the ",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const Text(
                        "Terms of Service",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const Text(
                        " & ",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const Text(
                        "Privacy Policy",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// 👇 Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAgreed ? _submitForm : null, // Only enabled if agreed
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Explicitly setting the black color
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

                  /// 👇 Already have an account? Sign In
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                        // Navigate to Sign In page
                      },
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.grey), // Make the whole text grey
                          children: [
                            const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.grey), // Grey color for "Already have an account?"
                            ),
                            const TextSpan(
                              text: "Sign In",
                              style: TextStyle(color: Colors.red), // Red color for "Sign In"
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
