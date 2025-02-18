import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides user-specific operations, e.g., retrieving user data, saving habits, etc.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches user data from Firestore, returning a map or null if not found.
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

  /// Saves a new habit document under the current user's 'habits' subcollection.
  Future<void> saveHabit(String uid, Map<String, dynamic> habitData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .add(habitData);
      print('Habit saved successfully.');
    } catch (e) {
      print('Error saving habit: $e');
    }
  }
}
