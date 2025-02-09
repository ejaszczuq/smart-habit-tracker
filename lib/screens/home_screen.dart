import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_habit_tracker/services/user_service.dart';
import 'package:smart_habit_tracker/widgets/calendar_widget.dart';
import 'package:smart_habit_tracker/typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch Firestore data for this user (if exists)
    final data = await _userService.getUserData(user.uid);
    if (!mounted) return;

    setState(() {
      userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('EEE., d.MM.yy').format(DateTime.now());

    // Always read the latest user from FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;

    // Decide which name to display:
    // 1) If Firestore user data has a "name", use that
    // 2) Otherwise, fall back to user.displayName from Firebase Auth
    // 3) Otherwise, default to "User"
    final displayName = userData?['name'] ?? user?.displayName ?? 'User';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: T.white_0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column: user's name, greeting, etc.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Hi, ',
                                style: T.h1,
                              ),
                              TextSpan(
                                text: displayName,
                                style: T.h1.copyWith(color: T.purple_2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "Let's make habits together!",
                          style: T.bodyRegular.copyWith(color: T.grey_1),
                        ),
                      ],
                    ),
                    // Right side: current date
                    Text(
                      currentDate,
                      style: T.bodyLargeBold.copyWith(color: T.grey_1),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
      body: const Column(
        children: [
          SizedBox(height: 7),
          Expanded(
            child: CalendarWidget(),
          ),
        ],
      ),
    );
  }
}
