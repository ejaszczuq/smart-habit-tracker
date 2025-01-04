import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_habit_tracker/home_screen.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggle;

  const LoginScreen({super.key, required this.onToggle});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = "", password = "";
  bool isPasswordVisible = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  userLogin() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = '';
        if (e.code == 'user-not-found') {
          errorMessage = 'No User Found for that Email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong Password';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: T.violet_1,
            content: Text(
              errorMessage,
              style: T.bodyRegular,
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

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: T.h2,
              ),
              const SizedBox(height: 4),
              Text(
                'Enter your credentials to continue',
                style: T.bodyRegularBold.copyWith(color: T.grey_1),
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32.0),
                  Center(
                    child: Image.asset(
                      'assets/images/login-screen-image.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 305,
                            child: TextFormField(
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
                                      color: T.white_1,
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
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
                          const SizedBox(height: 16.0),
                          SizedBox(
                            width: 305,
                            child: TextFormField(
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
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 90),
                              Transform.translate(
                                offset: const Offset(56, 0),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: T.black_1,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30.0),
                          SizedBox(
                            width: 315,
                            child: CustomButton(
                              text: 'LOGIN',
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  email = emailController.text;
                                  password = passwordController.text;
                                  userLogin();
                                }
                              },
                              style: T.buttonStandard,
                            ),
                          ),
                          const SizedBox(height: 27.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  border: Border.all(
                                    color: T.grey_0,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: SvgPicture.asset(
                                    'assets/icons/google-icon.svg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  border: Border.all(
                                    color: T.grey_0,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: SvgPicture.asset(
                                    'assets/icons/apple-icon.svg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          // Terms and Privacy Policy Text
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: T.bodyRegular.copyWith(color: T.grey_1),
                              children: [
                                const TextSpan(
                                    text:
                                        'By logging, you are agreeing with our '),
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: T.bodyRegularBold.copyWith(
                                    color: T.violet_0,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Handle Terms of Use tap
                                      print('Terms of Use clicked');
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: T.bodyRegularBold.copyWith(
                                    color: T.violet_0,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Handle Privacy Policy tap
                                      print('Privacy Policy clicked');
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "Don't have an account?" Section
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: T.bodyRegular.copyWith(color: T.grey_1),
                ),
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Text(
                    'Register',
                    style: T.bodyRegularBold.copyWith(
                      color: T.violet_0,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
