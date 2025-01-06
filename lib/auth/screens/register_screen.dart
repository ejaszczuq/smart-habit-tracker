import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_habit_tracker/navigation/main_navigation.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggle;

  const RegisterScreen({super.key, required this.onToggle});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String name = '', email = '', password = '', confirmPassword = '';

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isTermsAccepted = false;
  bool isKeyboardOpen = false;

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> registration() async {
    if (_formKey.currentState!.validate()) {
      // Update the email and password variables from the TextEditingController
      email = emailController.text.trim();
      password = passwordController.text.trim();

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Store user details in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        await userCredential.user
            ?.updateProfile(displayName: nameController.text.trim());
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

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = '';
        if (e.code == 'weak-password') {
          errorMessage = 'Password Provided is too Weak';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Account Already Exists';
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
  void initState() {
    super.initState();
    nameFocusNode.addListener(_handleFocusChange);
    emailFocusNode.addListener(_handleFocusChange);
    passwordFocusNode.addListener(_handleFocusChange);
    confirmPasswordFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (nameFocusNode.hasFocus ||
        emailFocusNode.hasFocus ||
        passwordFocusNode.hasFocus ||
        confirmPasswordFocusNode.hasFocus) {
      setState(() {
        isKeyboardOpen = true;
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted &&
            !nameFocusNode.hasFocus &&
            !emailFocusNode.hasFocus &&
            !passwordFocusNode.hasFocus &&
            !confirmPasswordFocusNode.hasFocus) {
          setState(() {
            isKeyboardOpen = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();

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

      /// GestureDetector
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name
                          const SizedBox(height: 15.0),
                          SizedBox(
                            width: 305,
                            child: TextFormField(
                              focusNode: nameFocusNode,
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'Your full name',
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 0, right: 10),
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
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 30, minHeight: 30),
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
                          const SizedBox(height: 8.0),

                          // Email
                          SizedBox(
                            width: 305,
                            child: TextFormField(
                              focusNode: emailFocusNode,
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'email@example.com',
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 0, right: 10),
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
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 30, minHeight: 30),
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
                              focusNode: passwordFocusNode,
                              controller: passwordController,
                              obscureText: !isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '*******',
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 0, right: 10),
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
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 30, minHeight: 30),
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
                              focusNode: confirmPasswordFocusNode,
                              controller: confirmPasswordController,
                              obscureText: !isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: '*******',
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 0, right: 10),
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
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 30, minHeight: 30),
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
                          const SizedBox(height: 18.0),

                          // Terms and Conditions Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: isTermsAccepted,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        isTermsAccepted = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By registering, you agree to the',
                                      style: T.captionSmall
                                          .copyWith(color: T.grey_1),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: T.captionSmall
                                            .copyWith(color: T.grey_1),
                                        children: [
                                          TextSpan(
                                            text: 'Terms of Use',
                                            style: const TextStyle(
                                              color: T.violet_0,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                print('Terms of Use tapped');
                                              },
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                              color: T.violet_0,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                print('Privacy Policy tapped');
                                              },
                                          ),
                                          const TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16.0),

                          // Sign Up Button
                          SizedBox(
                            width: 315,
                            child: CustomButton(
                              text: 'Sign Up',
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                if (!isTermsAccepted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please accept the terms and conditions to proceed.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                // Call the registration function
                                registration();
                              },
                              style: T.buttonStandard.copyWith(
                                backgroundColor:
                                    WidgetStateProperty.all(T.violet_0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22.0),

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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sign up',
                                          style: T.bodyRegularBold
                                              .copyWith(color: T.black_1),
                                        ),
                                        Text(
                                          'with Google',
                                          style: T.bodyRegular
                                              .copyWith(color: T.grey_1),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sign up',
                                          style: T.bodyRegularBold
                                              .copyWith(color: T.black_1),
                                        ),
                                        Text(
                                          'with Apple',
                                          style: T.bodyRegular
                                              .copyWith(color: T.grey_1),
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
            AnimatedOpacity(
              opacity: isKeyboardOpen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: T.violet_0.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: T.bodyRegular.copyWith(color: T.grey_1),
                    ),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Text(
                        'Log in',
                        style: T.bodyRegular.copyWith(
                          color: T.violet_0,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
