// import 'package:flutter/material.dart';
// import 'splash_screen.dart';
// import 'package:newarthub/Visitor/SignUp.dart';
// import 'Admin/AdLogin.dart';
// import 'package:newarthub/Visitor/ForgetPassword.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
//
// import 'package:newarthub/Admin/CreatEvent.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:newarthub/Visitor/LogIn.dart';
// import 'package:newarthub/Admin/Adhome.dart';
// import 'package:newarthub/Artist/uploadartwork.dart';
// import 'package:newarthub/Admin/AdProfile.dart';
// import 'package:newarthub/Visitor/VProfile.dart';
// import 'package:newarthub/Admin/AdChangePassword.dart';
// import 'package:newarthub/Admin/EditEventPage.dart';
// import 'package:newarthub/Artist/Arhome.dart';
// import 'package:newarthub/Visitor/Vhome.dart';
// import 'package:newarthub/Artist/ArProfile.dart';
// import 'package:newarthub/Artist/EditArtwork.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//
//   // Stripe Configuration
//   Stripe.publishableKey = 'pk_test_51QZiSj026qNc6iTxNcz5qYc4ixnZIDwfbXXdS5Xgeq2LEVdJhq1i4jWIj7nzPnv6WdicHkdwgIFDhCDSpv9HkAjP00GlltXFm1';
//    // ✅ This was missing!
//
//   runApp(const MyApp());
// }
//
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home:SplashScreen(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:newarthub/Visitor/ThemeProvider.dart';
import 'splash_screen.dart';
import 'package:newarthub/Visitor/SignUp.dart';
import 'Admin/AdLogin.dart';
import 'package:newarthub/Visitor/ForgetPassword.dart';
import 'package:newarthub/Visitor/LogIn.dart';
import 'package:newarthub/Admin/CreatEvent.dart';
import 'package:newarthub/Admin/Adhome.dart';
import 'package:newarthub/Artist/uploadartwork.dart';
import 'package:newarthub/Admin/AdProfile.dart';
import 'package:newarthub/Visitor/VProfile.dart';
import 'package:newarthub/Admin/AdChangePassword.dart';
import 'package:newarthub/Admin/EditEventPage.dart';
import 'package:newarthub/Artist/Arhome.dart';
import 'package:newarthub/Visitor/Vhome.dart';
import 'package:newarthub/Artist/ArProfile.dart';
import 'package:newarthub/Artist/EditArtwork.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Stripe.publishableKey = 'pk_test_51QZiSj026qNc6iTxNcz5qYc4ixnZIDwfbXXdS5Xgeq2LEVdJhq1i4jWIj7nzPnv6WdicHkdwgIFDhCDSpv9HkAjP00GlltXFm1';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArtHub',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
    );
  }
}
