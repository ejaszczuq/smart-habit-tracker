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
  bool isKeyboardOpen = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    emailFocusNode.addListener(_handleFocusChange);
    passwordFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (emailFocusNode.hasFocus || passwordFocusNode.hasFocus) {
      setState(() {
        isKeyboardOpen = true;
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted &&
            !emailFocusNode.hasFocus &&
            !passwordFocusNode.hasFocus) {
          setState(() {
            isKeyboardOpen = false;
          });
        }
      });
    }
  }

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
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32.0),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isKeyboardOpen ? 100 : 150,
                      height: isKeyboardOpen ? 100 : 150,
                      child: Center(
                        child: Image.asset(
                          'assets/images/login-screen-image.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 305,
                              child: TextFormField(
                                focusNode: emailFocusNode,
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'email@example.com',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0, right: 10),
                                    child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return T.gradient_0
                                            .createShader(bounds);
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
                                  contentPadding: const EdgeInsets.only(
                                      top: 10, bottom: 10),
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
                                focusNode: passwordFocusNode,
                                controller: passwordController,
                                obscureText: !isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: '*******',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0, right: 10),
                                    child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return T.gradient_0
                                            .createShader(bounds);
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
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  contentPadding: const EdgeInsets.only(
                                      top: 10, bottom: 10),
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
                            SizedBox(
                              width: 305,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: T.violet_0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20.0),
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
                            const SizedBox(height: 20.0),
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
                            AnimatedOpacity(
                              opacity: isKeyboardOpen ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: T.captionSmall
                                        .copyWith(color: T.grey_1),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'By logging, you are agreeing with our\n',
                                      ),
                                      TextSpan(
                                        text: 'Terms of Use',
                                        style: T.captionSmall.copyWith(
                                          color: T.violet_0,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            print('Terms of Use clicked');
                                          },
                                      ),
                                      const TextSpan(
                                        text: ' and ',
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: T.captionSmall.copyWith(
                                          color: T.violet_0,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            print('Privacy Policy clicked');
                                          },
                                      ),
                                    ],
                                  ),
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
                      'Don\'t have an account? ',
                      style: T.bodyRegular.copyWith(color: T.grey_1),
                    ),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Text(
                        'Register',
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
