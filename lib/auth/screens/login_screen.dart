import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = "", password = "";

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  userLogin() async {
    try {
      // Await the Firebase authentication call
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Ensure the widget is still mounted before navigating
      if (mounted) {
        // Navigate to HomeScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        String errorMessage = '';
        if (e.code == 'user-not-found') {
          errorMessage = 'No User Found for that Email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong Password';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle any other exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'An unexpected error occurred.',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ekran logowania'),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter E-mail';
                  }
                  return null;
                },
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                ),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter Password';
                  }
                  return null;
                },
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      email = emailController.text;
                      password = passwordController.text;
                    });
                    userLogin();
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(
                      vertical: 13.0, horizontal: 30.0),
                  decoration: BoxDecoration(
                      color: const Color(0xFF273671),
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
