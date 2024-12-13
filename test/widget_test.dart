import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Water Tracker smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('Water Tracker'), findsOneWidget);
    
    // Verify initial water intake is 0
    expect(find.text('0 ml'), findsOneWidget);
    
    // Verify the progress text is displayed
    expect(find.text('Daily Progress'), findsOneWidget);
    
    // Verify the percentage indicator exists
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('of daily goal'), findsOneWidget);
    
    // Verify the water intake buttons exist
    expect(find.text('+250 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);
    
    // Verify navigation items exist
    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
