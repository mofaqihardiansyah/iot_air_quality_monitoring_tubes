import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iot_air_quality_monitoring/services/auth_service.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'dart:developer' as dev;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    dev.log('Firebase initialization error: $e', name: 'Main');
    // Continue anyway to allow the app to start
  }

  runApp(const AirQualityApp());
}

class AirQualityApp extends StatelessWidget {
  const AirQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Air Quality Monitoring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      // This prevents default routes from being accessed directly
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const AuthWrapper());
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          );
        }
        // Note: Settings screen is pushed directly from dashboard, not using named routes
        return MaterialPageRoute(builder: (context) => const AuthWrapper());
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    try {
      // Add a timeout for the auth check
      bool isAuthenticated = _authService.isUserLoggedIn();
      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading app...'),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
