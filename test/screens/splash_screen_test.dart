import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/screens/placeholder_home_screen.dart';
import 'package:sim_interventions/screens/splash_screen.dart';

void main() {
  testWidgets('affiche le monogramme puis bascule apres 2 secondes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('S'), findsOneWidget);
    expect(find.byType(PlaceholderHomeScreen), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
    expect(find.text('S'), findsNothing);
  });
}
