import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';

import '../support/fake_token_storage.dart';

void main() {
  test('reveillerServeur appelle GET /health sans jeton', () async {
    http.Request? requeteRecue;
    final client = MockClient((request) async {
      requeteRecue = request;
      return http.Response('{"status":"ok"}', 200);
    });
    final service = AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage());

    await service.reveillerServeur();

    expect(requeteRecue?.method, 'GET');
    expect(requeteRecue?.url.path, '/health');
    expect(requeteRecue?.headers.containsKey('Authorization'), isFalse);
  });

  test('reveillerServeur ne leve jamais, meme hors ligne ou sur une erreur serveur', () async {
    final horsLigne = AuthService(
      apiClient: ApiClient(client: MockClient((request) async => throw Exception('hors ligne'))),
      storage: FakeTokenStorage(),
    );
    final erreurServeur = AuthService(
      apiClient: ApiClient(client: MockClient((request) async => http.Response('{}', 503))),
      storage: FakeTokenStorage(),
    );

    await expectLater(horsLigne.reveillerServeur(), completes);
    await expectLater(erreurServeur.reveillerServeur(), completes);
  });

  test('connecter stocke le jeton recu du backend', () async {
    final client = MockClient((request) async {
      return http.Response('{"accessToken":"jwt-fictif"}', 200);
    });
    final storage = FakeTokenStorage();
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    await service.connecter('koffi', 'technicien123');

    expect(await service.jetonActuel(), 'jwt-fictif');
  });

  test('connecter propage l erreur du backend sans stocker de jeton', () async {
    final client = MockClient((request) async {
      return http.Response('{"message":"Identifiant ou mot de passe incorrect"}', 401);
    });
    final storage = FakeTokenStorage();
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    await expectLater(
      service.connecter('koffi', 'mauvais'),
      throwsA(isA<ApiException>()),
    );
    expect(await service.jetonActuel(), isNull);
  });

  test('sessionValide est vrai seulement si un jeton est present', () async {
    final storage = FakeTokenStorage();
    final service = AuthService(apiClient: ApiClient(), storage: storage);

    expect(await service.sessionValide(), isFalse);

    await storage.ecrire('jwt', 'jwt-fictif');

    expect(await service.sessionValide(), isTrue);
  });

  test('nomTechnicien renvoie le nom du backend', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer jwt-fictif');
      return http.Response(
        '{"id":"tech-1","nom":"Koffi N\'Guessan","identifiant":"koffi","role":"TECHNICIEN"}',
        200,
      );
    });
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    expect(await service.nomTechnicien(), "Koffi N'Guessan");
  });

  test('nomTechnicien renvoie null sans jeton, sans appeler le reseau', () async {
    var appele = false;
    final client = MockClient((request) async {
      appele = true;
      return http.Response('{}', 200);
    });
    final service = AuthService(
      apiClient: ApiClient(client: client),
      storage: FakeTokenStorage(),
    );

    expect(await service.nomTechnicien(), isNull);
    expect(appele, isFalse);
  });

  test('nomTechnicien renvoie null sur une erreur serveur', () async {
    final client = MockClient((request) async => http.Response('{"message":"non autorise"}', 401));
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    expect(await service.nomTechnicien(), isNull);
  });

  test('nomTechnicien renvoie null sur une erreur reseau', () async {
    final client = MockClient((request) async => throw Exception('hors ligne'));
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    expect(await service.nomTechnicien(), isNull);
  });

  test('nomTechnicien met le nom en cache apres une recuperation reussie', () async {
    final client = MockClient((request) async {
      return http.Response('{"nom":"Koffi N\'Guessan"}', 200);
    });
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

    await service.nomTechnicien();

    expect(await storage.lire('nom_technicien'), "Koffi N'Guessan");
  });

  test(
    'nomTechnicien retombe sur le nom mis en cache si le reseau echoue '
    '(retour de Cedric le 2026-09-18 : le nom disparaissait hors ligne)',
    () async {
      final client = MockClient((request) async => throw Exception('hors ligne'));
      final storage = FakeTokenStorage();
      await storage.ecrire('jwt', 'jwt-fictif');
      await storage.ecrire('nom_technicien', "Koffi N'Guessan");
      final service = AuthService(apiClient: ApiClient(client: client), storage: storage);

      expect(await service.nomTechnicien(), "Koffi N'Guessan");
    },
  );

  test('deconnecter efface le jeton stocke', () async {
    final storage = FakeTokenStorage();
    await storage.ecrire('jwt', 'jwt-fictif');
    final service = AuthService(apiClient: ApiClient(), storage: storage);

    await service.deconnecter();

    expect(await service.jetonActuel(), isNull);
    expect(await service.sessionValide(), isFalse);
  });
}
