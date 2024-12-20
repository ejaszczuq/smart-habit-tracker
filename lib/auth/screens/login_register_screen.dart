import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/auth/screens/register_screen.dart';

import 'login_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isLogin = true; // Flaga wskazująca, który ekran jest aktywny

  void toggle() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Register'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                          color: const Color.fromARGB(255, 39, 54, 112),
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
                                color: isLogin ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: !isLogin ? Colors.white : Colors.black,
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

          // Dynamiczne przełączanie widgetów
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isLogin ? const LoginScreen() : const RegisterScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
