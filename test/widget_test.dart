// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:activex_gym_app/main.dart';

void main() {
  testWidgets('HomePage loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ActiveXGymApp());

    // Verify that the home page loads with the greeting
    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('William'), findsOneWidget);
    expect(find.text('Workout Progress!'), findsOneWidget);
    expect(find.text('Today Workouts (17)'), findsOneWidget);
    expect(find.text('Popular Exercise'), findsOneWidget);
  });
}
