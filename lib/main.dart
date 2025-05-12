import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:art_hub/Visitor/SignUp.dart';
import 'Admin/AdLogin.dart';
import 'Visitor/ForgetPassword.dart';
import 'Artist/ArSignUp.dart';
import 'Visitor/LogIn.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:art_hub/Admin/CreatEvent.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:CreateEventPage(),
    );
  }
}
