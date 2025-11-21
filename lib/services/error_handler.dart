import 'package:flutter/material.dart';

class ErrorHandler {
  // Display a generic error message
  static void showGenericError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Display a success message
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Handle Firebase-specific errors
  static void handleFirebaseError(BuildContext context, dynamic error) {
    String message = 'An error occurred';
    
    if (error is String) {
      message = error;
    } else if (error.toString().contains('Firebase')) {
      if (error.toString().contains('email-already-in-use')) {
        message = 'Email is already registered.';
      } else if (error.toString().contains('user-not-found')) {
        message = 'No user found with this email.';
      } else if (error.toString().contains('wrong-password')) {
        message = 'Incorrect password.';
      } else if (error.toString().contains('weak-password')) {
        message = 'Password is too weak.';
      } else if (error.toString().contains('invalid-email')) {
        message = 'Invalid email address.';
      } else {
        message = 'Authentication error occurred.';
      }
    } else if (error.toString().toLowerCase().contains('connection') ||
               error.toString().toLowerCase().contains('network')) {
      message = 'Network error. Please check your connection.';
    } else {
      message = error.toString();
    }
    
    showGenericError(context, message);
  }

  // Display a dialog for critical errors
  static Future<void> showCriticalErrorDialog(BuildContext context, String title, String message) async {
    if (context.mounted) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Handle data parsing errors
  static String handleDataParsingError(dynamic error) {
    if (error is ArgumentError) {
      return 'Invalid data format received';
    } else if (error is TypeError) {
      return 'Type error in data processing';
    } else {
      return 'Error processing data';
    }
  }
}