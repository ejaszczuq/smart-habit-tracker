import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/auth/screens/login_register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp() as Widget);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Habit Tracker',
      theme: ThemeData(
        scaffoldBackgroundColor: T.white_1,
        textTheme: GoogleFonts.alegreyaTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: T.white_1,
        ),
      ),
      home: const LoginRegisterScreen(),
    );
  }
}
