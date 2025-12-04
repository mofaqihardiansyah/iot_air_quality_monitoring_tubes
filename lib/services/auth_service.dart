import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as dev;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference get _usersRef => FirebaseDatabase.instance.ref().child('users');

  // Get current user
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      dev.log('Error getting current user: $e', name: 'AuthService');
      return null;
    }
  }

  // Check if user is signed in
  bool isUserLoggedIn() {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      dev.log('Error checking login status: $e', name: 'AuthService');
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Update last login time in the background (non-blocking)
      if (_auth.currentUser != null) {
        _usersRef.child(_auth.currentUser!.uid).update({
          'last_login': ServerValue.timestamp,
          'email': email,
        }).catchError((error) {
          // Handle error silently or log for debugging
          dev.log('Error updating last login: $error', name: 'AuthService');
        });
      }

      return true;
    } catch (e) {
      rethrow; // Let the calling function handle the error
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      if (userCredential.user != null) {
        // Store user data in Firebase Realtime Database (non-blocking)
        _usersRef.child(userCredential.user!.uid).set({
          'email': email,
          'created_at': ServerValue.timestamp,
          'last_login': ServerValue.timestamp,
        }).catchError((error) {
          // Handle error silently or log for debugging
          dev.log('Error creating user data: $error', name: 'AuthService');
        });
      }

      return true;
    } catch (e) {
      rethrow; // Let the calling function handle the error
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // In case of sign out failure, still clear local state as much as possible
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow; // Let the calling function handle the error
    }
  }
}