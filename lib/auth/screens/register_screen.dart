import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_habit_tracker/screens/home_screen.dart';
import 'package:smart_habit_tracker/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String name = '', email = '', password = '', confirmPassword = '';

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> registration() async {
    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'name': nameController.text,
          'email': emailController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await userCredential.user?.updateProfile(displayName: name);

        await userCredential.user?.reload();

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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: T.violet_1,
              content: Text(
                errorMessage,
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          );
        }
      } catch (e) {
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create your account',
                style: T.h2,
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in your details to sign up',
                style: T.bodyRegularBold.copyWith(color: T.grey_1),
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //const SizedBox(height: 2.0),
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: T.grey_0.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Placeholder for image',
                  style: T.bodyRegular.copyWith(color: T.grey_1),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16.0),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    SizedBox(
                      width: 305,
                      child: TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Your full name',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 0, right: 10),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return T.gradient_0.createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: SvgPicture.asset(
                                'assets/icons/write-icon.svg',
                              ),
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 30, minHeight: 30),
                          contentPadding:
                              const EdgeInsets.only(top: 10, bottom: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Email
                    SizedBox(
                      width: 305,
                      child: TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'email@example.com',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 0, right: 10),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return T.gradient_0.createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: SvgPicture.asset(
                                'assets/icons/email-icon.svg',
                              ),
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 30, minHeight: 30),
                          contentPadding:
                              const EdgeInsets.only(top: 10, bottom: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Password
                    SizedBox(
                      width: 305,
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '*******',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 0, right: 10),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return T.gradient_0.createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: SvgPicture.asset(
                                'assets/icons/password-icon.svg',
                              ),
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            child: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: T.grey_1,
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 30, minHeight: 30),
                          contentPadding:
                              const EdgeInsets.only(top: 10, bottom: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Confirm Password
                    SizedBox(
                      width: 305,
                      child: TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: '*******',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 0, right: 10),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return T.gradient_0.createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: SvgPicture.asset(
                                'assets/icons/password-icon.svg',
                              ),
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible;
                              });
                            },
                            child: Icon(
                              isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: T.grey_1,
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 30, minHeight: 30),
                          contentPadding:
                              const EdgeInsets.only(top: 10, bottom: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Sign Up button
                    SizedBox(
                      width: 315,
                      child: CustomButton(
                        text: 'Sign Up',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              name = nameController.text;
                              email = emailController.text;
                              password = passwordController.text;
                              confirmPassword = confirmPasswordController.text;
                            });
                            registration();
                          }
                        },
                        style: T.buttonStandard.copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(T.violet_0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Google / Apple signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            border: Border.all(
                              color: T.grey_0,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign up',
                                    style: T.bodyRegularBold
                                        .copyWith(color: T.black_1),
                                  ),
                                  Text(
                                    'with Google',
                                    style:
                                        T.bodyRegular.copyWith(color: T.grey_1),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                'assets/icons/google-icon.svg',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            border: Border.all(
                              color: T.grey_0,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign up',
                                    style: T.bodyRegularBold
                                        .copyWith(color: T.black_1),
                                  ),
                                  Text(
                                    'with Apple',
                                    style:
                                        T.bodyRegular.copyWith(color: T.grey_1),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                'assets/icons/apple-icon.svg',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
