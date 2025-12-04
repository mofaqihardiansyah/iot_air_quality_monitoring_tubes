import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as dev;

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference get _usersRef => FirebaseDatabase.instance.ref().child('users');

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
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
        } catch (e) {
          dev.log('Error getting user profile: $e', name: 'UserProfileService');
        }
      }
    } catch (e) {
      dev.log('Firebase error getting user profile: $e', name: 'UserProfileService');
    }
    return null;
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update Firebase Auth profile
        if (displayName != null || photoURL != null) {
          await user.updateProfile(
            displayName: displayName,
            photoURL: photoURL,
          );
        }

        // Update in Realtime Database (non-blocking)
        final updates = <String, dynamic>{};
        if (displayName != null) updates['display_name'] = displayName;
        if (photoURL != null) updates['photo_url'] = photoURL;
        updates['updated_at'] = ServerValue.timestamp;

        if (updates.isNotEmpty) {
          _usersRef.child(user.uid).update(updates).catchError((error) {
            dev.log('Error updating user profile in database: $error', name: 'UserProfileService');
          });
        }
      }
    } catch (e) {
      dev.log('Firebase error updating user profile: $e', name: 'UserProfileService');
    }
  }

  // Update user settings/preferences
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _usersRef.child(user.uid).child('settings').update(settings).catchError((error) {
          dev.log('Error updating user settings: $error', name: 'UserProfileService');
        });
      }
    } catch (e) {
      dev.log('Firebase error updating settings: $e', name: 'UserProfileService');
    }
  }

  // Get user settings/preferences
  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
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
        } catch (e) {
          dev.log('Error getting user settings: $e', name: 'UserProfileService');
        }
      }
    } catch (e) {
      dev.log('Firebase error getting user settings: $e', name: 'UserProfileService');
    }
    return null;
  }

  // Check if user has admin privileges (if applicable)
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final snapshot = await _usersRef.child(user.uid).child('is_admin').get();
          return snapshot.value == true;
        } catch (e) {
          dev.log('Error checking admin status: $e', name: 'UserProfileService');
          return false;
        }
      }
    } catch (e) {
      dev.log('Firebase error checking admin status: $e', name: 'UserProfileService');
    }
    return false;
  }
}