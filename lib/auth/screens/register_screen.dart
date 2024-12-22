import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String name = '', email = '', password = '', confirmPassword = '';
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> registration() async {
    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save additional user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid) // User ID as document ID
            .set({
          'name': nameController.text,
          'email': emailController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update profile with the user's name
        await userCredential.user?.updateProfile(displayName: name);

        // Reload the user to reflect the changes
        await userCredential.user?.reload();

        // Ensure the widget is still mounted before showing a SnackBar or navigating
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registered Successfully',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = '';
        if (e.code == 'weak-password') {
          errorMessage = 'Password Provided is too Weak';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Account Already exists';
        } else {
          errorMessage = 'An error occurred. Please try again.';
        }

        // Ensure the widget is still mounted before showing a SnackBar
        if (mounted) {
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
        // Handle unexpected exceptions
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
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ekran rejestracji'),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter Name';
                  }
                  return null;
                },
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                ),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter Email';
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
                //TODO Ikonka do pokazywania hasła ? Prosta flaga zmieniająca wartość obscure
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Confirm you password';
                  }
                  if (value != passwordController.text) {
                    return 'Password provided doesn\'t match first one';
                  }
                  return null;
                },
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm your Password',
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      email = emailController.text;
                      name = nameController.text;
                      password = passwordController.text;
                      confirmPassword = confirmPasswordController.text;
                    });
                  }
                  registration();
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
                      'Sign Up',
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
