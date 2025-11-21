import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is signed in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Update last login time in users node
      if (_auth.currentUser != null) {
        await _usersRef.child(_auth.currentUser!.uid).update({
          'last_login': ServerValue.timestamp,
          'email': email,
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
        // Store user data in Firebase Realtime Database
        await _usersRef.child(userCredential.user!.uid).set({
          'email': email,
          'created_at': ServerValue.timestamp,
          'last_login': ServerValue.timestamp,
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