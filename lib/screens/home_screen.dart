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
    String currentDate = DateFormat('EEE., d.MM.yy').format(DateTime.now());
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
