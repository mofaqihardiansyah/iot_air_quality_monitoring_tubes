// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:iot_air_quality_monitoring/main.dart';
import 'package:iot_air_quality_monitoring/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Air Quality App test', (WidgetTester tester) async {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AirQualityApp());

    // Verify that the dashboard appears
    expect(find.text('Air Quality Dashboard'), findsOneWidget);
  });
}
