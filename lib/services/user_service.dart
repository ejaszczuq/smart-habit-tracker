import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Future<void> saveHabit(String uid, Map<String, dynamic> habitData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .add(habitData);
      print('Habit saved successfully');
    } catch (e) {
      print('Error saving habit: $e');
    }
  }
}
