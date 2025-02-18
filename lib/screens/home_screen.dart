import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_habit_tracker/services/user_service.dart';
import 'package:smart_habit_tracker/widgets/calendar_widget.dart';
import 'package:smart_habit_tracker/typography.dart';

/// Landing screen after login, showing a calendar and basic welcome info.
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

  /// Loads additional user data (e.g., display name) from Firestore.
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await _userService.getUserData(user.uid);
    if (!mounted) return;
    setState(() {
      userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('EEE., d.MM.yy').format(DateTime.now());
    final user = FirebaseAuth.instance.currentUser;

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
                    /// Greeting with user name
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
                    /// Displays current date
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
