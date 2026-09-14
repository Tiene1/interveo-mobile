import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/sync_service.dart';

import '../support/fake_token_storage.dart';

const _interventionJson = '''
{
  "id": "i-1",
  "nomClient": "Hotel Ivoire",
  "adresse": "Boulevard de Marseille, Cocody",
  "telephone1": "0102030405",
  "telephone2": null,
  "geolocalisation": null,
  "motifSignale": null,
  "datePrevue": "2026-09-20T09:00:00.000Z",
  "technicienId": "tech-1",
  "creeParId": "directeur-1",
  "typeEquipement": null,
  "problemeConstate": null,
  "travauxRealises": null,
  "statut": "PLANIFIEE",
  "dateRealisation": null,
  "creeLe": "2026-09-12T00:00:00.000Z",
  "misAJourLe": "2026-09-12T00:00:00.000Z"
}
''';

const _interventionAnnuleeJson = '''
{
  "id": "i-1",
  "nomClient": "Hotel Ivoire",
  "adresse": "Boulevard de Marseille, Cocody",
  "telephone1": "0102030405",
  "telephone2": null,
  "geolocalisation": null,
  "motifSignale": null,
  "datePrevue": "2026-09-14T09:00:00.000Z",
  "technicienId": "tech-1",
  "creeParId": "directeur-1",
  "typeEquipement": null,
  "problemeConstate": null,
  "travauxRealises": null,
  "statut": "ANNULEE",
  "dateRealisation": null,
  "creeLe": "2026-09-14T09:00:00.000Z",
  "misAJourLe": "2026-09-14T16:00:00.000Z"
}
''';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('tirerInterventions upsert chaque intervention recue avec statutSync confirme', () async {
    final client = MockClient((request) async => http.Response('[$_interventionJson]', 200));
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final nombre = await service.tirerInterventions();

    expect(nombre, 1);
    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention, isNotNull);
    expect(intervention!.nomClient, 'Hotel Ivoire');
    expect(intervention.statut, StatutIntervention.planifiee);
    expect(intervention.statutSync, StatutSync.confirme);
  });

  test('tirerInterventions appelle depuis= avec le dernier misAJourLe local', () async {
    await db.interventionDao.upsert(InterventionsCompanion.insert(
      idServeur: 'i-0',
      nomClient: 'Existant',
      adresse: 'Cocody',
      telephone1: '0102030405',
      datePrevue: DateTime(2026, 9, 10, 9),
      technicienId: 'tech-1',
      creeParId: 'directeur-1',
      statut: StatutIntervention.planifiee,
      creeLe: DateTime(2026, 9, 10, 9),
      misAJourLe: DateTime.utc(2026, 9, 11, 8, 30),
      statutSync: StatutSync.confirme,
    ));

    Uri? urlAppelee;
    final client = MockClient((request) async {
      urlAppelee = request.url;
      return http.Response('[]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await service.tirerInterventions();

    expect(urlAppelee?.queryParameters['depuis'], '2026-09-11T08:30:00.000Z');
  });

  test('tirerInterventions omet depuis quand la base locale est vide', () async {
    Uri? urlAppelee;
    final client = MockClient((request) async {
      urlAppelee = request.url;
      return http.Response('[]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await service.tirerInterventions();

    expect(urlAppelee?.queryParameters.containsKey('depuis'), isFalse);
  });

  test('tirerInterventions propage une ApiException sur une reponse d erreur', () async {
    final client = MockClient((request) async => http.Response('{"message":"non autorise"}', 401));
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await expectLater(service.tirerInterventions(), throwsA(isA<ApiException>()));
  });

  Future<void> seedeClotureLocale(AppDatabase db, {String idServeur = 'i-1'}) {
    final maintenant = DateTime(2026, 9, 14, 9);
    return db.interventionDao.upsert(InterventionsCompanion.insert(
      idServeur: idServeur,
      nomClient: 'Hotel Ivoire',
      adresse: 'Cocody',
      telephone1: '0102030405',
      datePrevue: maintenant,
      technicienId: 'tech-1',
      creeParId: 'directeur-1',
      problemeConstate: const Value('Climatiseur en panne'),
      travauxRealises: const Value('Filtre nettoye'),
      statut: StatutIntervention.realisee,
      dateRealisation: Value(DateTime(2026, 9, 14, 15)),
      creeLe: maintenant,
      misAJourLe: maintenant,
      statutSync: StatutSync.local,
    ));
  }

  test('pousserInterventions n appelle pas le reseau si rien a pousser', () async {
    var appele = false;
    final client = MockClient((request) async {
      appele = true;
      return http.Response('[]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final conflits = await service.pousserInterventions();

    expect(conflits, 0);
    expect(appele, isFalse);
  });

  test('pousserInterventions envoie les clotures locales et marque confirme', () async {
    await seedeClotureLocale(db);

    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/sync/interventions');
      return http.Response('[{"idServeur":"i-1","resultat":"CONFIRME"}]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final conflits = await service.pousserInterventions();

    expect(conflits, 0);
    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statutSync, StatutSync.confirme);
  });

  test('pousserInterventions compte les conflits sans modifier la ligne locale', () async {
    await seedeClotureLocale(db);

    final client = MockClient(
      (request) async => http.Response(
        '[{"idServeur":"i-1","resultat":"CONFLIT","raison":"Intervention ANNULEE"}]',
        200,
      ),
    );
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final conflits = await service.pousserInterventions();

    expect(conflits, 1);
    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statutSync, StatutSync.local);
  });

  test('synchroniser pousse puis retire, et renvoie le nombre de conflits', () async {
    await seedeClotureLocale(db);

    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response(
          '[{"idServeur":"i-1","resultat":"CONFLIT","raison":"Intervention ANNULEE"}]',
          200,
        );
      }
      return http.Response('[$_interventionAnnuleeJson]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final conflits = await service.synchroniser();

    expect(conflits, 1);
    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statut, StatutIntervention.annulee);
    expect(intervention.statutSync, StatutSync.confirme);
  });
}
