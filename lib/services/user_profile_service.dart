import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _usersRef.child(user.uid).get();
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Convert keys to string to ensure proper access
        final stringData = <String, dynamic>{};
        data.forEach((key, value) {
          stringData[key.toString()] = value;
        });
        return stringData;
      }
    }
    return null;
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await user.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }
      
      // Update in Realtime Database
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoURL != null) updates['photo_url'] = photoURL;
      updates['updated_at'] = ServerValue.timestamp;
      
      if (updates.isNotEmpty) {
        await _usersRef.child(user.uid).update(updates);
      }
    }
  }

  // Update user settings/preferences
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _usersRef.child(user.uid).child('settings').update(settings);
    }
  }

  // Get user settings/preferences
  Future<Map<String, dynamic>?> getUserSettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _usersRef.child(user.uid).child('settings').get();
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Convert keys to string to ensure proper access
        final stringData = <String, dynamic>{};
        data.forEach((key, value) {
          stringData[key.toString()] = value;
        });
        return stringData;
      }
    }
    return null;
  }

  // Check if user has admin privileges (if applicable)
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _usersRef.child(user.uid).child('is_admin').get();
      return snapshot.value == true;
    }
    return false;
  }
}