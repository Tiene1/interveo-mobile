import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/detail_intervention_screen.dart';
import 'package:sim_interventions/screens/mes_interventions_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';
import 'package:sim_interventions/services/sync_service.dart';
import 'package:sim_interventions/services/token_storage.dart';
import 'package:sim_interventions/state/interventions_provider.dart';
import 'package:sim_interventions/theme/design_tokens.dart';

import '../support/app_test_scope.dart';
import '../support/fake_token_storage.dart';

/// Fausse implementation du canal de plateforme de connectivity_plus : evite
/// le vrai canal (absent en test widget) et permet de simuler une coupure
/// puis un retour de connexion via [controleur].
class _ConnectivitePlateformeFausse extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  final controleur = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> etatInitial = [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => controleur.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => etatInitial;
}

/// Renvoie un [ResultatSynchro] fixe sans toucher au reseau ni au disque :
/// evite de faire passer un testWidgets par le vrai chemin d'upload de photo
/// (multipart, I/O fichier reelle), qui reste bloque indefiniment sous
/// l'horloge simulee de testWidgets (cf. docs/architecture.md, piege de test
/// du ticket "push des photos").
class _SyncServiceResultatFixe extends SyncService {
  _SyncServiceResultatFixe({
    required super.interventionDao,
    required super.photoDao,
    required super.apiClient,
    required super.tokenStorage,
    required this.resultat,
  });

  final ResultatSynchro resultat;

  @override
  Future<ResultatSynchro> synchroniser() async => resultat;
}

InterventionsCompanion _intervention({
  required String idServeur,
  required String nomClient,
  required DateTime datePrevue,
  StatutIntervention statut = StatutIntervention.planifiee,
  StatutSync statutSync = StatutSync.confirme,
}) {
  return InterventionsCompanion.insert(
    idServeur: idServeur,
    nomClient: nomClient,
    adresse: 'Cocody',
    telephone1: '0102030405',
    datePrevue: datePrevue,
    technicienId: 'tech-1',
    creeParId: 'directeur-1',
    statut: statut,
    creeLe: datePrevue,
    misAJourLe: datePrevue,
    statutSync: statutSync,
  );
}

Future<AppDatabase> _dbAvecInterventions(List<InterventionsCompanion> interventions) async {
  final db = AppDatabase(NativeDatabase.memory());
  for (final intervention in interventions) {
    await db.interventionDao.upsert(intervention);
  }
  return db;
}

Widget _app(AppDatabase db) => appTest(home: const MesInterventionsScreen(), db: db);

Widget _appAvecClient(
  AppDatabase db,
  MockClient client, {
  AuthService? authService,
  SyncService? syncService,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      syncServiceProvider.overrideWithValue(
        syncService ??
            SyncService(
              interventionDao: db.interventionDao,
              photoDao: db.photoDao,
              apiClient: ApiClient(client: client),
              tokenStorage: FakeTokenStorage(),
            ),
      ),
      authServiceProvider.overrideWithValue(
        authService ??
            AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage()),
      ),
    ],
    child: const MaterialApp(home: MesInterventionsScreen()),
  );
}

/// Drift programme un timer interne (duree 0) quand une requete .watch()
/// se ferme ; sans ce pump supplementaire apres la destruction du widget,
/// Flutter detecte ce timer comme "pending" a la fin du test (issue connue
/// simolus3/drift#3323).
Future<void> _videLeTimerDeFermeture(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late _ConnectivitePlateformeFausse connectivite;

  setUp(() {
    connectivite = _ConnectivitePlateformeFausse();
    ConnectivityPlatform.instance = connectivite;
  });

  tearDown(() => connectivite.controleur.close());

  testWidgets("affiche l'etat vide quand aucune intervention n'est attribuee", (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucune intervention'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche les interventions non annulees triees par date prevue', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-tard', nomClient: 'Client Tard', datePrevue: DateTime(2026, 9, 20, 14)),
      _intervention(idServeur: 'i-tot', nomClient: 'Client Tot', datePrevue: DateTime(2026, 9, 12, 9)),
      _intervention(idServeur: 'i-annulee', nomClient: 'Client Annule', datePrevue: DateTime(2026, 9, 15, 10), statut: StatutIntervention.annulee),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Client Tot'), findsOneWidget);
    expect(find.text('Client Tard'), findsOneWidget);
    expect(find.text('Client Annule'), findsNothing);

    final positionTot = tester.getTopLeft(find.text('Client Tot')).dy;
    final positionTard = tester.getTopLeft(find.text('Client Tard')).dy;
    expect(positionTot, lessThan(positionTard));

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('les onglets filtrent par statut avec le bon compte', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
      _intervention(idServeur: 'i-2', nomClient: 'SGBCI Plateau', datePrevue: DateTime(2026, 9, 13, 9), statut: StatutIntervention.realisee),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Toutes'), findsOneWidget);
    expect(find.text('Hotel Ivoire'), findsOneWidget);
    expect(find.text('SGBCI Plateau'), findsOneWidget);

    await tester.tap(find.text('Réalisées'));
    await tester.pumpAndSettle();

    expect(find.text('Hotel Ivoire'), findsNothing);
    expect(find.text('SGBCI Plateau'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche la ligne date du jour au dessus du titre', (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kickerDateHeure')), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche TIREZ POUR SYNCHRONISER au dessus d une liste non vide', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('TIREZ POUR SYNCHRONISER'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets("n affiche pas l indice de synchro quand la liste est vide", (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('TIREZ POUR SYNCHRONISER'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('l indicateur du bouton de synchro est vert quand tout est synchronise', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    final indicateur = tester.widget<Container>(find.byKey(const Key('indicateurSynchro')));
    expect((indicateur.decoration as BoxDecoration).color, success);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets(
    'l indicateur du bouton de synchro est orange quand une cloture reste a synchroniser',
    (tester) async {
      final db = await _dbAvecInterventions([
        _intervention(
          idServeur: 'i-1',
          nomClient: 'Hotel Ivoire',
          datePrevue: DateTime(2026, 9, 12, 9),
          statutSync: StatutSync.local,
        ),
      ]);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      final indicateur = tester.widget<Container>(find.byKey(const Key('indicateurSynchro')));
      expect((indicateur.decoration as BoxDecoration).color, warning);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets(
    'l indicateur du bouton de synchro est rouge quand une photo est en conflit',
    (tester) async {
      final db = await _dbAvecInterventions([
        _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
      ]);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await db.photoDao.ajouter(PhotosCompanion.insert(
        interventionIdLocal: 'i-1',
        categorie: CategoriePhoto.avant,
        cheminLocal: '/donnees/test/photo.jpg',
        statutSync: StatutSync.conflit,
      ));
      await tester.pumpAndSettle();

      final indicateur = tester.widget<Container>(find.byKey(const Key('indicateurSynchro')));
      expect((indicateur.decoration as BoxDecoration).color, danger);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets("indique 'A synchroniser' pour une intervention modifiee localement", (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(
        idServeur: 'i-1',
        nomClient: 'Hotel Ivoire',
        datePrevue: DateTime(2026, 9, 12, 9),
        statutSync: StatutSync.local,
      ),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('À synchroniser'), findsOneWidget);
    expect(find.text('Synchronisée'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets(
    "indique 'Photos a synchroniser' quand la cloture est confirmee mais pas ses photos",
    (tester) async {
      final db = await _dbAvecInterventions([
        _intervention(
          idServeur: 'i-1',
          nomClient: 'Hotel Ivoire',
          datePrevue: DateTime(2026, 9, 12, 9),
        ),
      ]);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      // Photo ajoutee apres la synchro automatique d'ouverture (donc jamais
      // poussee dans ce test) : verifie l'effet reactif du badge sans passer
      // par le vrai upload multipart, dont la lecture fichier reelle ne se
      // resout pas sous l'horloge simulee d'un testWidgets (meme famille de
      // piege que le timer Drift #3323, deja documentee sur ce projet).
      await db.photoDao.ajouter(PhotosCompanion.insert(
        interventionIdLocal: 'i-1',
        categorie: CategoriePhoto.avant,
        cheminLocal: '/donnees/test/photo.jpg',
        statutSync: StatutSync.local,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Photos à synchroniser'), findsOneWidget);
      expect(find.text('Synchronisée'), findsNothing);
      expect(find.text('À synchroniser'), findsNothing);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets(
    "indique 'Photo en echec' quand une photo est definitivement en conflit",
    (tester) async {
      final db = await _dbAvecInterventions([
        _intervention(
          idServeur: 'i-1',
          nomClient: 'Hotel Ivoire',
          datePrevue: DateTime(2026, 9, 12, 9),
        ),
      ]);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await db.photoDao.ajouter(PhotosCompanion.insert(
        interventionIdLocal: 'i-1',
        categorie: CategoriePhoto.avant,
        cheminLocal: '/donnees/test/photo.jpg',
        statutSync: StatutSync.conflit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Photo en échec'), findsOneWidget);
      expect(find.text('Photos à synchroniser'), findsNothing);
      expect(find.text('Synchronisée'), findsNothing);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets("affiche 'Synchronise a l instant' juste apres une synchro reussie", (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text("Synchronisé à l'instant"), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets("n affiche pas d indicateur de synchro si la synchro d ouverture echoue", (tester) async {
    final db = await _dbAvecInterventions([]);
    final client = MockClient((request) async => http.Response('{"message":"Erreur interne"}', 500));

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();

    expect(find.textContaining('Synchronisé'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets(
    "affiche l heure de synchro persistee si la synchro d ouverture echoue",
    (tester) async {
      final db = await _dbAvecInterventions([]);
      final stockageSynchro = FakeTokenStorage();
      await stockageSynchro.ecrire(
        cleDerniereSynchro,
        DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      );
      final client = MockClient((request) async => http.Response('{"message":"Erreur"}', 500));
      final syncService = SyncService(
        interventionDao: db.interventionDao,
        photoDao: db.photoDao,
        apiClient: ApiClient(client: client),
        tokenStorage: stockageSynchro,
      );

      await tester.pumpWidget(_appAvecClient(db, client, syncService: syncService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Synchronisé il y a 5 min'), findsOneWidget);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets('affiche le nom du technicien recupere via GET auth/moi', (tester) async {
    final db = await _dbAvecInterventions([]);
    final clientSynchro = MockClient((request) async => http.Response('[]', 200));
    final storageAvecJeton = FakeTokenStorage();
    await storageAvecJeton.ecrire('jwt', 'jwt-fictif');
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient(
          (request) async => http.Response(
            '{"id":"tech-1","nom":"Koffi N\'Guessan","identifiant":"koffi","role":"TECHNICIEN"}',
            200,
          ),
        ),
      ),
      storage: storageAvecJeton,
    );

    await tester.pumpWidget(
      _appAvecClient(db, clientSynchro, authService: authService),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nomTechnicien')), findsOneWidget);
    expect(find.text("Koffi N'Guessan"), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('n affiche pas de nom si la recuperation du profil echoue', (tester) async {
    final db = await _dbAvecInterventions([]);
    final clientSynchro = MockClient((request) async => http.Response('[]', 200));

    await tester.pumpWidget(_appAvecClient(db, clientSynchro));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nomTechnicien')), findsNothing);
    expect(find.textContaining('Synchronisé'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('taper sur une tuile ouvre le detail de l intervention', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
    ]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hotel Ivoire'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailInterventionScreen), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche le code et le message du serveur en cas d erreur API', (tester) async {
    final db = await _dbAvecInterventions([]);
    final client = MockClient(
      (request) async => http.Response('{"message":"Erreur interne"}', 500),
    );

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();

    expect(find.text('Erreur du serveur (500) : Erreur interne'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche un message generique pour une erreur inattendue', (tester) async {
    final db = await _dbAvecInterventions([]);
    final client = MockClient((request) async => throw Exception('panne reseau'));

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();

    expect(
      find.text('Synchronisation impossible : Exception: panne reseau'),
      findsOneWidget,
    );

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche un message quand une photo est en conflit apres la synchro', (tester) async {
    final db = await _dbAvecInterventions([
      _intervention(idServeur: 'i-1', nomClient: 'Hotel Ivoire', datePrevue: DateTime(2026, 9, 12, 9)),
    ]);
    final client = MockClient((request) async => http.Response('[]', 200));
    final syncService = _SyncServiceResultatFixe(
      interventionDao: db.interventionDao,
      photoDao: db.photoDao,
      apiClient: ApiClient(client: client),
      tokenStorage: FakeTokenStorage(),
      resultat: const ResultatSynchro(conflitsClotures: 0, photosEnConflit: 1),
    );

    await tester.pumpWidget(_appAvecClient(db, client, syncService: syncService));
    await tester.pumpAndSettle();

    expect(
      find.text("1 photo n'a pas pu être synchronisée (catégorie déjà complète)."),
      findsOneWidget,
    );

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('une reconnexion detectee apres une coupure relance la synchro', (tester) async {
    final db = await _dbAvecInterventions([]);
    var appels = 0;
    final client = MockClient((request) async {
      appels++;
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();
    final appelsInitiaux = appels;

    connectivite.controleur.add([ConnectivityResult.none]);
    await tester.pumpAndSettle();
    connectivite.controleur.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();

    expect(appels, appelsInitiaux + 1);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('rester connecte sans coupure ne redeclenche pas de synchro', (tester) async {
    final db = await _dbAvecInterventions([]);
    var appels = 0;
    final client = MockClient((request) async {
      appels++;
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();
    final appelsInitiaux = appels;

    connectivite.controleur.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();

    expect(appels, appelsInitiaux);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('le retour au premier plan relance la synchro', (tester) async {
    final db = await _dbAvecInterventions([]);
    var appels = 0;
    final client = MockClient((request) async {
      appels++;
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(_appAvecClient(db, client));
    await tester.pumpAndSettle();
    final appelsInitiaux = appels;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(appels, appelsInitiaux + 1);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche le bandeau hors ligne si l appareil demarre sans connexion', (tester) async {
    connectivite.etatInitial = [ConnectivityResult.none];
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bandeauHorsLigne')), findsOneWidget);
    expect(find.text('Hors ligne — données locales'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('n affiche pas le bandeau hors ligne si l appareil demarre connecte', (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bandeauHorsLigne')), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('le bandeau hors ligne apparait et disparait selon les evenements de connectivite', (tester) async {
    final db = await _dbAvecInterventions([]);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bandeauHorsLigne')), findsNothing);

    connectivite.controleur.add([ConnectivityResult.none]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bandeauHorsLigne')), findsOneWidget);

    connectivite.controleur.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bandeauHorsLigne')), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });
}
