import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/auth/screens/register_screen.dart';
import 'package:smart_habit_tracker/auth/screens/login_screen.dart';
import 'package:smart_habit_tracker/typography.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({Key? key}) : super(key: key);

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isLogin = true;

  // Toggle between login and register forms
  void toggle() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Toggle button for switching forms
          Padding(
            padding:
                const EdgeInsets.only(bottom: 30.0, left: 16.0, right: 16.0),
            child: GestureDetector(
              onTap: toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.grey.shade300,
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: isLogin
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        height: 50,
                        width: 125,
                        decoration: BoxDecoration(
                          color: T.violet_0,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: isLogin ? T.white_0 : T.black_0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: !isLogin ? T.white_0 : T.black_0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Switch between LoginScreen and RegisterScreen
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isLogin
                  ? LoginScreen(onToggle: toggle)
                  : RegisterScreen(onToggle: toggle),
            ),
          ),
        ],
      ),
    );
  }
}
