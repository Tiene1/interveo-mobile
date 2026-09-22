import 'dart:convert';
import 'dart:io';

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

const _interventionAvecPhotosJson = '''
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
  "problemeConstate": "Compresseur HS",
  "travauxRealises": "Remplacement compresseur",
  "statut": "REALISEE",
  "dateRealisation": "2026-09-20T15:00:00.000Z",
  "creeLe": "2026-09-12T00:00:00.000Z",
  "misAJourLe": "2026-09-20T15:00:00.000Z",
  "photos": [
    {"id": "p-serveur-1", "categorie": "AVANT"},
    {"id": "p-serveur-2", "categorie": "APRES"}
  ]
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await expectLater(service.tirerInterventions(), throwsA(isA<ApiException>()));
  });

  test(
    'tirerInterventions repeuple les metadonnees des photos recues, sans fichier local',
    () async {
      final client = MockClient(
        (request) async => http.Response('[$_interventionAvecPhotosJson]', 200),
      );
      final service = SyncService(
        interventionDao: db.interventionDao,
        photoDao: db.photoDao,
        apiClient: ApiClient(client: client),
        tokenStorage: FakeTokenStorage(),
      );

      await service.tirerInterventions();

      final photos = await db.photoDao.listerPourIntervention('i-1');
      expect(photos, hasLength(2));
      expect(photos.every((p) => p.cheminLocal == null), isTrue);
      expect(photos.every((p) => p.statutSync == StatutSync.confirme), isTrue);
      expect(
        photos.map((p) => p.idServeur).toSet(),
        {'p-serveur-1', 'p-serveur-2'},
      );
    },
  );

  test(
    'tirerInterventions ne duplique pas une photo deja connue localement (meme idServeur)',
    () async {
      await db.interventionDao.upsert(InterventionsCompanion.insert(
        idServeur: 'i-1',
        nomClient: 'Hotel Ivoire',
        adresse: 'Cocody',
        telephone1: '0102030405',
        datePrevue: DateTime(2026, 9, 20, 9),
        technicienId: 'tech-1',
        creeParId: 'directeur-1',
        statut: StatutIntervention.realisee,
        creeLe: DateTime(2026, 9, 12),
        misAJourLe: DateTime(2026, 9, 12),
        statutSync: StatutSync.confirme,
      ));
      await db.photoDao.ajouterMetadonnee(
        idServeur: 'p-serveur-1',
        interventionIdLocal: 'i-1',
        categorie: CategoriePhoto.avant,
      );

      final client = MockClient(
        (request) async => http.Response('[$_interventionAvecPhotosJson]', 200),
      );
      final service = SyncService(
        interventionDao: db.interventionDao,
        photoDao: db.photoDao,
        apiClient: ApiClient(client: client),
        tokenStorage: FakeTokenStorage(),
      );

      await service.tirerInterventions();

      final photos = await db.photoDao.listerPourIntervention('i-1');
      expect(photos, hasLength(2));
    },
  );

  test('telechargerPhoto appelle GET /photos/:id et renvoie les bytes', () async {
    final octets = [1, 2, 3, 4];
    Uri? urlAppelee;
    final client = MockClient((request) async {
      urlAppelee = request.url;
      return http.Response.bytes(octets, 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final resultat = await service.telechargerPhoto('p-serveur-1');

    expect(urlAppelee?.path, '/photos/p-serveur-1');
    expect(resultat, octets);
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
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
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final resultat = await service.synchroniser();

    expect(resultat.conflitsClotures, 1);
    expect(resultat.photosEnConflit, 0);
    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statut, StatutIntervention.annulee);
    expect(intervention.statutSync, StatutSync.confirme);
  });

  test('derniereSynchroReussie est null tant qu aucune synchro n a reussi', () async {
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(),
      tokenStorage: FakeTokenStorage(),
    );

    expect(await service.derniereSynchroReussie(), isNull);
  });

  test('synchroniser persiste l heure de succes, lisible via derniereSynchroReussie', () async {
    final client = MockClient((request) async => http.Response('[]', 200));
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await service.synchroniser();

    final derniere = await service.derniereSynchroReussie();
    expect(derniere, isNotNull);
    expect(DateTime.now().difference(derniere!).inSeconds, lessThan(5));
  });

  Future<File> creerFichierTemp() async {
    final fichier = File(
      '${Directory.systemTemp.path}/sync_service_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await fichier.writeAsBytes([0, 1, 2, 3]);
    return fichier;
  }

  Future<int> seedePhotoLocale(AppDatabase db, {required String cheminLocal}) {
    return db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.avant,
      cheminLocal: Value(cheminLocal),
      statutSync: StatutSync.local,
    ));
  }

  test(
    'tirerInterventions vide le fichier local des photos confirmees d une intervention desormais Realisee',
    () async {
      final fichier = await creerFichierTemp();
      await db.interventionDao.upsert(InterventionsCompanion.insert(
        idServeur: 'i-1',
        nomClient: 'Hotel Ivoire',
        adresse: 'Cocody',
        telephone1: '0102030405',
        datePrevue: DateTime(2026, 9, 20, 9),
        technicienId: 'tech-1',
        creeParId: 'directeur-1',
        statut: StatutIntervention.planifiee,
        creeLe: DateTime(2026, 9, 12),
        misAJourLe: DateTime(2026, 9, 12),
        statutSync: StatutSync.confirme,
      ));
      await db.photoDao.ajouter(PhotosCompanion.insert(
        idServeur: const Value('p-serveur-1'),
        interventionIdLocal: 'i-1',
        categorie: CategoriePhoto.avant,
        cheminLocal: Value(fichier.path),
        statutSync: StatutSync.confirme,
      ));

      final client = MockClient(
        (request) async => http.Response('[$_interventionAvecPhotosJson]', 200),
      );
      final service = SyncService(
        interventionDao: db.interventionDao,
        photoDao: db.photoDao,
        apiClient: ApiClient(client: client),
        tokenStorage: FakeTokenStorage(),
      );

      await service.tirerInterventions();

      final photo = await db.photoDao.parIdServeur('p-serveur-1');
      expect(photo!.cheminLocal, isNull);
      expect(await fichier.exists(), isFalse);
    },
  );

  test('pousserPhotos n appelle pas le reseau si rien a pousser', () async {
    var appele = false;
    final client = MockClient((request) async {
      appele = true;
      return http.Response('[]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final echecs = await service.pousserPhotos();

    expect(echecs, 0);
    expect(appele, isFalse);
  });

  test('pousserPhotos envoie chaque photo locale et marque confirme avec l idServeur', () async {
    await seedeClotureLocale(db);
    final fichier = await creerFichierTemp();
    addTearDown(() => fichier.delete());
    await seedePhotoLocale(db, cheminLocal: fichier.path);

    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/interventions/i-1/photos');
      return http.Response('{"id":"p-serveur-1"}', 201);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final echecs = await service.pousserPhotos();

    expect(echecs, 0);
    final photos = await db.photoDao.listerPourIntervention('i-1');
    expect(photos.single.idServeur, 'p-serveur-1');
    expect(photos.single.statutSync, StatutSync.confirme);
  });

  test('pousserPhotos compte un 409 comme echec sans arreter les photos suivantes', () async {
    await seedeClotureLocale(db);
    final fichier1 = await creerFichierTemp();
    final fichier2 = await creerFichierTemp();
    addTearDown(() => fichier1.delete());
    addTearDown(() => fichier2.delete());
    await seedePhotoLocale(db, cheminLocal: fichier1.path);
    await seedePhotoLocale(db, cheminLocal: fichier2.path);

    var appels = 0;
    final client = MockClient((request) async {
      appels++;
      if (appels == 1) {
        return http.Response('{"message":"Maximum 2 photos AVANT par intervention"}', 409);
      }
      return http.Response('{"id":"p-serveur-2"}', 201);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final echecs = await service.pousserPhotos();

    expect(echecs, 1);
    expect(appels, 2);
    final photos = await db.photoDao.listerPourIntervention('i-1');
    expect(photos.where((p) => p.statutSync == StatutSync.confirme), hasLength(1));
    expect(photos.where((p) => p.statutSync == StatutSync.conflit), hasLength(1));
  });

  test('une photo en conflit n est plus jamais reessayee lors d un appel suivant', () async {
    await seedeClotureLocale(db);
    final fichier = await creerFichierTemp();
    addTearDown(() => fichier.delete());
    await seedePhotoLocale(db, cheminLocal: fichier.path);

    var appels = 0;
    final client = MockClient((request) async {
      appels++;
      return http.Response('{"message":"Maximum 2 photos AVANT par intervention"}', 409);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    expect(await service.pousserPhotos(), 1);
    expect(appels, 1);

    expect(await service.pousserPhotos(), 0);
    expect(appels, 1, reason: 'la photo en conflit ne doit plus declencher de requete');
  });

  test('synchroniser renvoie le nombre de photos en conflit', () async {
    await seedeClotureLocale(db);
    final fichier = await creerFichierTemp();
    addTearDown(() => fichier.delete());
    await seedePhotoLocale(db, cheminLocal: fichier.path);

    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.contains('/photos')) {
        return http.Response('{"message":"Maximum 2 photos AVANT par intervention"}', 409);
      }
      if (request.method == 'POST') {
        return http.Response('[{"idServeur":"i-1","resultat":"CONFIRME"}]', 200);
      }
      return http.Response('[]', 200);
    });
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    final resultat = await service.synchroniser();

    expect(resultat.conflitsClotures, 0);
    expect(resultat.photosEnConflit, 1);
  });

  test('pousserPhotos propage une erreur autre que 409', () async {
    await seedeClotureLocale(db);
    final fichier = await creerFichierTemp();
    addTearDown(() => fichier.delete());
    await seedePhotoLocale(db, cheminLocal: fichier.path);

    final client = MockClient((request) async => http.Response('{"message":"non autorise"}', 401));
    final service = SyncService(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
    );

    await expectLater(service.pousserPhotos(), throwsA(isA<ApiException>()));
  });

  group('tirerInterventions protege la saisie locale en cours (bug reel du 2026-09-22)', () {
    Future<void> seedeSaisieEnCours(AppDatabase db) async {
      final maintenant = DateTime(2026, 9, 22, 9);
      await db.interventionDao.upsert(InterventionsCompanion.insert(
        idServeur: 'i-1',
        nomClient: 'Hotel Ivoire',
        adresse: 'Cocody',
        telephone1: '0102030405',
        datePrevue: maintenant,
        technicienId: 'tech-1',
        creeParId: 'directeur-1',
        statut: StatutIntervention.planifiee,
        statutSync: StatutSync.confirme,
        creeLe: maintenant,
        misAJourLe: maintenant,
      ));
      // Simule la saisie du technicien : mettreAJourSaisie() est ce qu'appelle
      // reellement l'ecran de completion (onChange/flush), pas un upsert direct.
      await db.interventionDao.mettreAJourSaisie(
        'i-1',
        problemeConstate: const Value('Compresseur HS'),
        travauxRealises: const Value('Diagnostic en cours'),
      );
    }

    test(
      'un pull pendant la saisie n efface pas le texte deja tape (statut encore PLANIFIEE)',
      () async {
        await seedeSaisieEnCours(db);
        // Le serveur renvoie l'etat d'AVANT la saisie (toujours PLANIFIEE,
        // champs nuls) : c'est exactement ce que renverrait un pull declenche
        // avant que le technicien n'ait termine de completer l'intervention.
        final client = MockClient((request) async => http.Response('[$_interventionJson]', 200));
        final service = SyncService(
          interventionDao: db.interventionDao,
          photoDao: db.photoDao,
          apiClient: ApiClient(client: client),
          tokenStorage: FakeTokenStorage(),
        );

        await service.tirerInterventions();

        final intervention = await db.interventionDao.parId('i-1');
        expect(intervention!.problemeConstate, 'Compresseur HS');
        expect(intervention.travauxRealises, 'Diagnostic en cours');
        expect(intervention.statutSync, StatutSync.local);
      },
    );

    test(
      'sans le correctif, le pull efface bien le texte tape : confirme que le test precedent teste le bon bug',
      () async {
        await seedeSaisieEnCours(db);
        // Reproduit exactement ce que fait _versCompanion() sur la reponse du
        // serveur (Value(null) explicite, pas Value.absent()) : c'est ce qui
        // rend le champ "present dans le SET de l'upsert", donc ecrasable -
        // au contraire d'un champ simplement omis. Bypass volontaire du
        // correctif de tirerInterventions() (appel direct au DAO), pour
        // prouver que le mecanisme repose bien sur Drift/insertOnConflictUpdate
        // et non sur un artefact du test precedent.
        final json = jsonDecode(_interventionJson) as Map<String, dynamic>;
        await db.interventionDao.upsert(InterventionsCompanion.insert(
          idServeur: json['id'] as String,
          nomClient: json['nomClient'] as String,
          adresse: json['adresse'] as String,
          telephone1: json['telephone1'] as String,
          problemeConstate: Value(json['problemeConstate'] as String?),
          travauxRealises: Value(json['travauxRealises'] as String?),
          datePrevue: DateTime.parse(json['datePrevue'] as String),
          technicienId: json['technicienId'] as String,
          creeParId: json['creeParId'] as String,
          statut: StatutIntervention.planifiee,
          creeLe: DateTime.parse(json['creeLe'] as String),
          misAJourLe: DateTime.parse(json['misAJourLe'] as String),
          statutSync: StatutSync.confirme,
        ));

        final intervention = await db.interventionDao.parId('i-1');
        expect(intervention!.problemeConstate, isNull,
            reason: 'l upsert inconditionnel efface bien le texte : c est le bug reel');
      },
    );

    test(
      'une cloture deja tentee (LOCAL + REALISEE) reste ecrasable par le pull (conflit, comportement inchange)',
      () async {
        await seedeClotureLocale(db);
        final client = MockClient((request) async => http.Response('[$_interventionAnnuleeJson]', 200));
        final service = SyncService(
          interventionDao: db.interventionDao,
          photoDao: db.photoDao,
          apiClient: ApiClient(client: client),
          tokenStorage: FakeTokenStorage(),
        );

        await service.tirerInterventions();

        final intervention = await db.interventionDao.parId('i-1');
        expect(intervention!.statut, StatutIntervention.annulee);
        expect(intervention.statutSync, StatutSync.confirme);
      },
    );
  });
}
