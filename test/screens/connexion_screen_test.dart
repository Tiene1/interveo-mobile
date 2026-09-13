import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/screens/connexion_screen.dart';
import 'package:sim_interventions/screens/mes_interventions_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';

import '../support/app_test_scope.dart';
import '../support/fake_token_storage.dart';

Widget _app(Widget home) => appTest(home: home);

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
  Future<void> saisir(WidgetTester tester, String identifiant, String motDePasse) async {
    await tester.enterText(find.byKey(const Key('champIdentifiant')), identifiant);
    await tester.enterText(find.byKey(const Key('champMotDePasse')), motDePasse);
  }

  testWidgets('affiche le titre et les champs a l etat normal', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());

    await tester.pumpWidget(_app(ConnexionScreen(authService: service)));

    expect(find.textContaining('Bon'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Utilisez vos identifiants professionnels'), findsOneWidget);
  });

  testWidgets('le mot de passe est masque puis visible via le bouton oeil', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());
    await tester.pumpWidget(_app(ConnexionScreen(authService: service)));

    final champ = tester.widget<TextField>(find.byKey(const Key('champMotDePasse')));
    expect(champ.obscureText, isTrue);

    await tester.tap(find.byKey(const Key('boutonVisibiliteMotDePasse')));
    await tester.pump();

    final champApres = tester.widget<TextField>(find.byKey(const Key('champMotDePasse')));
    expect(champApres.obscureText, isFalse);
  });

  testWidgets('connexion reussie : navigue vers Mes interventions', (tester) async {
    final client = MockClient((request) async => http.Response('{"accessToken":"jwt-fictif"}', 200));
    final service = AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage());

    await tester.pumpWidget(_app(ConnexionScreen(authService: service)));
    await saisir(tester, 'koffi.nguessan', 'technicien123');

    await tester.tap(find.byKey(const Key('boutonConnexion')));
    await tester.pump();

    expect(find.text('Vérification en cours…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(MesInterventionsScreen), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('connexion echouee : affiche le message d erreur du backend', (tester) async {
    final client = MockClient((request) async {
      return http.Response('{"message":"Identifiant ou mot de passe incorrect"}', 401);
    });
    final service = AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage());

    await tester.pumpWidget(_app(ConnexionScreen(authService: service)));
    await saisir(tester, 'koffi.nguessan', 'mauvais');

    await tester.tap(find.byKey(const Key('boutonConnexion')));
    await tester.pumpAndSettle();

    expect(find.text('Identifiant ou mot de passe incorrect'), findsOneWidget);
    expect(find.text('Vérifiez vos identifiants et réessayez'), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsOneWidget);
  });
}
