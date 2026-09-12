import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/screens/connexion_screen.dart';
import 'package:sim_interventions/screens/placeholder_home_screen.dart';
import 'package:sim_interventions/screens/splash_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';

import '../support/fake_token_storage.dart';

void main() {
  testWidgets('sans session, bascule vers l ecran de connexion apres 2 secondes', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());

    await tester.pumpWidget(MaterialApp(home: SplashScreen(authService: service)));

    expect(find.text('S'), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ConnexionScreen), findsOneWidget);
  });

  testWidgets('avec une session valide, bascule directement vers la suite', (tester) async {
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(), storage: storage);

    await tester.pumpWidget(MaterialApp(home: SplashScreen(authService: service)));

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsNothing);
  });
}
