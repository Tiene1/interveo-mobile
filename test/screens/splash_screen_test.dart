import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/screens/connexion_screen.dart';
import 'package:sim_interventions/screens/mes_interventions_screen.dart';
import 'package:sim_interventions/screens/splash_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

import '../support/fake_token_storage.dart';

Widget _app(Widget home) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))],
    child: MaterialApp(home: home),
  );
}

/// Drift programme un timer interne (duree 0) quand une requete .watch()
/// se ferme ; sans ce pump supplementaire apres la destruction du widget,
/// Flutter detecte ce timer comme "pending" a la fin du test (issue connue
/// simolus3/drift#3323). Necessaire uniquement quand le test atteint
/// MesInterventionsScreen, qui ouvre ce flux.
Future<void> _videLeTimerDeFermeture(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('sans session, bascule vers l ecran de connexion apres 2 secondes', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());

    await tester.pumpWidget(_app(SplashScreen(authService: service)));

    expect(find.text('S'), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ConnexionScreen), findsOneWidget);
  });

  testWidgets('avec une session valide, bascule directement vers Mes interventions', (tester) async {
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(), storage: storage);

    await tester.pumpWidget(_app(SplashScreen(authService: service)));

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(MesInterventionsScreen), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });
}
