import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/services/api_client.dart';

void main() {
  test('post renvoie le corps decode sur une reponse 200', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/login');
      return http.Response('{"accessToken":"jwt-fictif"}', 200);
    });

    final reponse = await ApiClient(client: client).post(
      '/auth/login',
      corps: {'identifiant': 'koffi', 'motDePasse': 'x'},
    );

    expect(reponse['accessToken'], 'jwt-fictif');
  });

  test('post leve une ApiException avec le message du backend sur 401', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"statusCode":401,"message":"Identifiant ou mot de passe incorrect","error":"Unauthorized"}',
        401,
      );
    });

    await expectLater(
      ApiClient(client: client).post('/auth/login', corps: {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Identifiant ou mot de passe incorrect'),
      ),
    );
  });

  test('post joint un message liste en une seule chaine', () async {
    final client = MockClient((request) async {
      return http.Response('{"message":["champ requis","autre erreur"]}', 400);
    });

    await expectLater(
      ApiClient(client: client).post('/auth/login', corps: {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'champ requis, autre erreur')),
    );
  });

  test('get ajoute l en-tete Authorization quand un jeton est fourni', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer jwt-fictif');
      return http.Response('{}', 200);
    });

    await ApiClient(client: client).get('/auth/moi', jeton: 'jwt-fictif');
  });

  test('getListe decode un tableau JSON a la racine', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/sync/interventions');
      return http.Response('[{"id":"i-1"},{"id":"i-2"}]', 200);
    });

    final reponse = await ApiClient(client: client).getListe('/sync/interventions');

    expect(reponse, hasLength(2));
    expect((reponse.first as Map)['id'], 'i-1');
  });

  test('getListe leve une ApiException sur une reponse d erreur', () async {
    final client = MockClient((request) async => http.Response('{"message":"non autorise"}', 401));

    await expectLater(
      ApiClient(client: client).getListe('/sync/interventions'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('postListe envoie un tableau JSON et decode le tableau de reponse', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/sync/interventions');
      expect(request.body, '[{"idServeur":"i-1"}]');
      return http.Response('[{"idServeur":"i-1","resultat":"CONFIRME"}]', 200);
    });

    final reponse = await ApiClient(client: client).postListe(
      '/sync/interventions',
      corps: [
        {'idServeur': 'i-1'},
      ],
    );

    expect(reponse, hasLength(1));
    expect((reponse.first as Map)['resultat'], 'CONFIRME');
  });

  test('postListe leve une ApiException sur une reponse d erreur', () async {
    final client = MockClient((request) async => http.Response('{"message":"corps invalide"}', 400));

    await expectLater(
      ApiClient(client: client).postListe('/sync/interventions', corps: const []),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
    );
  });
}
