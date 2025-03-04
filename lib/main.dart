import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_habit_tracker/auth/screens/login_register_screen.dart';
import 'package:smart_habit_tracker/navigation/main_navigation.dart';
import 'package:smart_habit_tracker/typography.dart';

/// The entry point of the Flutter application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Habit Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: T.violet_0),
        useMaterial3: true,
        scaffoldBackgroundColor: T.white_1,
        textTheme: GoogleFonts.alegreyaTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: T.white_1,
        ),
      ),
      home: const AuthenticationRouter(),
    );
  }
}

class AuthenticationRouter extends StatelessWidget {
  const AuthenticationRouter({super.key});

  /// Listens to FirebaseAuth changes to determine whether the user is logged in.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const MainNavigation();
        } else {
          return const LoginRegisterScreen();
        }
      },
    );
  }
}


