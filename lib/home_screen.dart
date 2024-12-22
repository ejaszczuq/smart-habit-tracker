import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final user = FirebaseAuth.instance.currentUser;
final displayName = user?.displayName ?? 'User';

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? uid = user?.uid;
    Map<String, dynamic>? data = await _userService.getUserData(uid!);

    if (data != null) {
      setState(() {
        userData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'WITAJ $displayName - FirebaseAuth\n\nUtworzono ${userData?['createdAt']}- Firestore',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
