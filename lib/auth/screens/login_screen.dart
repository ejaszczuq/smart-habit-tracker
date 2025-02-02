import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_habit_tracker/navigation/main_navigation.dart';
import 'package:smart_habit_tracker/typography.dart';
import 'package:smart_habit_tracker/widgets/custom_button.dart';

// For Google Sign-In
import 'package:google_sign_in/google_sign_in.dart';

// For Apple Sign-In
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Logs in the user using email/password
  Future<void> userLogin() async {
    try {
      email = emailController.text.trim();
      password = passwordController.text.trim();

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'An unknown error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No User Found for that Email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong Password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: T.violet_1,
          content: Text(errorMessage, style: T.bodyRegular),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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

  /// Displays a dialog to reset the password
  Future<void> _showResetPasswordDialog() async {
    // Pre-fill with whatever is in emailController, or leave it blank
    final TextEditingController resetEmailController =
        TextEditingController(text: emailController.text.trim());

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email to receive a password reset link:',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final resetEmail = resetEmailController.text.trim();
                if (resetEmail.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: resetEmail);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password reset link sent to $resetEmail',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ?? 'Error sending reset email',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }
                  }
                }

                // Only pop if we are still mounted
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Send Reset Email'),
            ),
          ],
        );
      },
    );
  }

  /// Sign in with Google. If the user doesn't exist, Firebase creates a new one.
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in flow
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get the credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // If it's a new user, create a document in Firestore (optional)
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final user = userCredential.user!;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      debugPrint('Google Sign-In Firebase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.message ?? 'Google sign-in failed.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Google Sign-In general error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An unexpected error occurred during Google sign-in.'),
        ),
      );
    }
  }

  /// Sign in with Apple (iOS/macOS only). If new, create doc in Firestore.
  Future<void> signInWithApple() async {
    // For Apple sign-in, ensure you have the correct setup on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Sign-In is only supported on iOS/macOS.'),
        ),
      );
      return;
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        accessToken: appleCredential.authorizationCode,
        idToken: appleCredential.identityToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final user = userCredential.user!;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple Sign-In Firebase error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.message ?? 'Apple sign-in failed.'),
        ),
      );
    } catch (e) {
      debugPrint('Apple Sign-In general error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An unexpected error occurred during Apple sign-in.'),
        ),
      );
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
              Text('Welcome back!', style: T.h2),
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // MAIN CONTENT
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
                            // EMAIL
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
                                      minWidth: 30, minHeight: 30),
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

                            // PASSWORD
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
                                      minWidth: 30, minHeight: 30),
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

                            // FORGOT PASSWORD
                            SizedBox(
                              width: 305,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: _showResetPasswordDialog,
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

                            // LOGIN BUTTON
                            SizedBox(
                              width: 315,
                              child: CustomButton(
                                text: 'LOGIN',
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    userLogin();
                                  }
                                },
                                style: T.buttonStandard,
                              ),
                            ),
                            const SizedBox(height: 20.0),

                            // GOOGLE + APPLE SIGN-IN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: signInWithGoogle,
                                  child: Container(
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
                                ),
                                const SizedBox(width: 20),
                                if (Platform.isIOS || Platform.isMacOS)
                                  GestureDetector(
                                    onTap: signInWithApple,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white30,
                                        border: Border.all(
                                          color: T.grey_0,
                                          width: 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
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
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16.0),

                            // TERMS / PRIVACY REMINDER
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
                                      const TextSpan(text: ' and '),
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

            // FOOTER
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
