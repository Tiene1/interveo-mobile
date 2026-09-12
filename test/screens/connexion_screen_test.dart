import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/screens/connexion_screen.dart';
import 'package:sim_interventions/screens/placeholder_home_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';

import '../support/fake_token_storage.dart';

void main() {
  Future<void> saisir(WidgetTester tester, String identifiant, String motDePasse) async {
    await tester.enterText(find.byKey(const Key('champIdentifiant')), identifiant);
    await tester.enterText(find.byKey(const Key('champMotDePasse')), motDePasse);
  }

  testWidgets('affiche le titre et les champs a l etat normal', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());

    await tester.pumpWidget(MaterialApp(home: ConnexionScreen(authService: service)));

    expect(find.textContaining('Bon'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Utilisez vos identifiants professionnels'), findsOneWidget);
  });

  testWidgets('le mot de passe est masque puis visible via le bouton oeil', (tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());
    await tester.pumpWidget(MaterialApp(home: ConnexionScreen(authService: service)));

    final champ = tester.widget<TextField>(find.byKey(const Key('champMotDePasse')));
    expect(champ.obscureText, isTrue);

    await tester.tap(find.byKey(const Key('boutonVisibiliteMotDePasse')));
    await tester.pump();

    final champApres = tester.widget<TextField>(find.byKey(const Key('champMotDePasse')));
    expect(champApres.obscureText, isFalse);
  });

  testWidgets('connexion reussie : navigue vers l ecran suivant', (tester) async {
    final client = MockClient((request) async => http.Response('{"accessToken":"jwt-fictif"}', 200));
    final service = AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage());

    await tester.pumpWidget(MaterialApp(home: ConnexionScreen(authService: service)));
    await saisir(tester, 'koffi.nguessan', 'technicien123');

    await tester.tap(find.byKey(const Key('boutonConnexion')));
    await tester.pump();

    expect(find.text('Vérification en cours…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
  });

  testWidgets('connexion echouee : affiche le message d erreur du backend', (tester) async {
    final client = MockClient((request) async {
      return http.Response('{"message":"Identifiant ou mot de passe incorrect"}', 401);
    });
    final service = AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage());

    await tester.pumpWidget(MaterialApp(home: ConnexionScreen(authService: service)));
    await saisir(tester, 'koffi.nguessan', 'mauvais');

    await tester.tap(find.byKey(const Key('boutonConnexion')));
    await tester.pumpAndSettle();

    expect(find.text('Identifiant ou mot de passe incorrect'), findsOneWidget);
    expect(find.text('Vérifiez vos identifiants et réessayez'), findsOneWidget);
    expect(find.byType(ConnexionScreen), findsOneWidget);
  });
}
