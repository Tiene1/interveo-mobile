import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/completer_intervention_screen.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/photo_stockage_service.dart';
import 'package:sim_interventions/services/sync_service.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

import '../support/fake_token_storage.dart';

/// Fausse implementation : evite d'invoquer le vrai ImagePicker (canal de
/// plateforme absent en test widget), meme principe que FakeTokenStorage.
class _PhotoStockageServiceFausse extends PhotoStockageService {
  int compteur = 0;

  @override
  Future<String?> capturer(ImageSource source) async {
    compteur++;
    return '/donnees/test/photo-$compteur.jpg';
  }
}

InterventionsCompanion _intervention({
  String idServeur = 'i-1',
  String? problemeConstate,
  String? travauxRealises,
  StatutIntervention statut = StatutIntervention.planifiee,
  StatutSync statutSync = StatutSync.confirme,
  DateTime? dateRealisation,
}) {
  final datePrevue = DateTime(2026, 9, 14, 9);
  return InterventionsCompanion.insert(
    idServeur: idServeur,
    nomClient: 'Hotel Ivoire',
    adresse: 'Boulevard Hassan II, Cocody',
    telephone1: '0102030405',
    datePrevue: datePrevue,
    technicienId: 'tech-1',
    creeParId: 'directeur-1',
    problemeConstate: Value(problemeConstate),
    travauxRealises: Value(travauxRealises),
    statut: statut,
    dateRealisation: Value(dateRealisation),
    creeLe: datePrevue,
    misAJourLe: datePrevue,
    statutSync: statutSync,
  );
}

Future<AppDatabase> _dbAvec(InterventionsCompanion intervention) async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.interventionDao.upsert(intervention);
  return db;
}

/// syncServiceProvider est surcharge ici (client HTTP factice, jamais de vrai
/// reseau) car la cloture declenche desormais une tentative de synchro
/// immediate (cf. _demanderCloture) : sans cette surcharge, l'ecran retombe
/// sur le vrai SecureTokenStorage, qui bloque indefiniment en test faute de
/// canal de plateforme (meme piege deja documente pour SyncService/AuthService
/// sur MesInterventionsScreen).
Widget _app(
  AppDatabase db, {
  String idServeur = 'i-1',
  PhotoStockageService? photoStockage,
  MockClient? client,
}) {
  client ??= MockClient((request) async => http.Response('[]', 200));
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      syncServiceProvider.overrideWithValue(
        SyncService(
          interventionDao: db.interventionDao,
          photoDao: db.photoDao,
          apiClient: ApiClient(client: client),
          tokenStorage: FakeTokenStorage(),
        ),
      ),
      if (photoStockage != null)
        photoStockageServiceProvider.overrideWithValue(photoStockage),
    ],
    child: MaterialApp(home: CompleterInterventionScreen(idServeur: idServeur)),
  );
}

Future<int> _ajouterPhoto(
  AppDatabase db, {
  String idServeur = 'i-1',
  required CategoriePhoto categorie,
  String cheminLocal = '/donnees/test/photo.jpg',
}) {
  return db.photoDao.ajouter(
    PhotosCompanion.insert(
      interventionIdLocal: idServeur,
      categorie: categorie,
      cheminLocal: cheminLocal,
      statutSync: StatutSync.local,
    ),
  );
}

/// Drift programme un timer interne (duree 0) a la fermeture d'un .watch()
/// (issue connue simolus3/drift#3323).
Future<void> _videLeTimerDeFermeture(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('le bouton Cloturer est desactive tant que les 2 champs ne sont pas remplis', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    final bouton = tester.widget<ElevatedButton>(find.byKey(const Key('boutonCloturer')));
    expect(bouton.onPressed, isNull);
    expect(find.text('Renseignez le problème et les travaux pour clôturer'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('saisir les 2 champs active le bouton Cloturer et enregistre localement', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Climatiseur en panne');
    await tester.enterText(find.byType(TextField).last, 'Filtre nettoye');
    await tester.pump();

    final bouton = tester.widget<ElevatedButton>(find.byKey(const Key('boutonCloturer')));
    expect(bouton.onPressed, isNotNull);

    // Laisse l'anti-rebond (400ms) se declencher.
    await tester.pump(const Duration(milliseconds: 500));

    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.problemeConstate, 'Climatiseur en panne');
    expect(intervention.travauxRealises, 'Filtre nettoye');
    expect(intervention.statutSync, StatutSync.local);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets(
    "sauvegarde le texte en attente si l ecran est quitte avant la fin de l anti-rebond",
    (tester) async {
      final db = await _dbAvec(_intervention());

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Texte tape juste avant de quitter');
      // Pas de pump(400ms) : l'anti-rebond n'a pas encore declenche quand
      // l'ecran se ferme, dispose() doit forcer l'ecriture.
      await tester.pump();
      await _videLeTimerDeFermeture(tester);

      final intervention = await db.interventionDao.parId('i-1');
      expect(intervention!.problemeConstate, 'Texte tape juste avant de quitter');
      expect(intervention.statutSync, StatutSync.local);
    },
  );

  testWidgets('cloturer via la modale de confirmation passe l intervention en Realisee', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
    ));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boutonCloturer')));
    await tester.pumpAndSettle();

    expect(find.text('Clôturer cette intervention ?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boutonConfirmerCloture')));
    await tester.pumpAndSettle();

    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statut, StatutIntervention.realisee);
    expect(intervention.statutSync, StatutSync.local);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets(
    'cloturer declenche une tentative de synchro immediate sans attendre le bouton',
    (tester) async {
      final db = await _dbAvec(_intervention(
        problemeConstate: 'Climatiseur en panne',
        travauxRealises: 'Filtre nettoye',
      ));
      var appelsClotures = 0;
      final client = MockClient((request) async {
        if (request.url.path.contains('/sync/interventions') && request.method == 'POST') {
          appelsClotures++;
          return http.Response(
            '[{"idServeur":"i-1","resultat":"CONFIRME"}]',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      await tester.pumpWidget(_app(db, client: client));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boutonCloturer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boutonConfirmerCloture')));
      await tester.pumpAndSettle();

      // Constat Cedric le 2026-09-14 : la cloture doit partir sans clic sur
      // le bouton de synchro de "Mes interventions" si l'appareil est deja
      // connecte.
      expect(appelsClotures, 1, reason: 'la cloture aurait du partir sans intervention manuelle');
      final intervention = await db.interventionDao.parId('i-1');
      expect(intervention!.statutSync, StatutSync.confirme);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets(
    'cloturer redirige jusqu a l ecran racine, pas seulement l ecran precedent',
    (tester) async {
      final db = await _dbAvec(_intervention(
        problemeConstate: 'Climatiseur en panne',
        travauxRealises: 'Filtre nettoye',
      ));
      final client = MockClient((request) async => http.Response('[]', 200));
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            syncServiceProvider.overrideWithValue(
              SyncService(
                interventionDao: db.interventionDao,
                photoDao: db.photoDao,
                apiClient: ApiClient(client: client),
                tokenStorage: FakeTokenStorage(),
              ),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Center(child: Text('Mes interventions (racine)'))),
          ),
        ),
      );

      // Simule la pile reelle Detail -> Completer, deux niveaux au-dessus de
      // la racine (Mes interventions).
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Detail (ecran intermediaire)'))),
        ),
      );
      await tester.pumpAndSettle();
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const CompleterInterventionScreen(idServeur: 'i-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boutonCloturer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('boutonConfirmerCloture')));
      await tester.pumpAndSettle();

      // Demande de Cedric le 2026-09-14 : retour direct a "Mes interventions",
      // pas seulement a l'ecran precedent (Detail).
      expect(find.text('Mes interventions (racine)'), findsOneWidget);
      expect(find.text('Detail (ecran intermediaire)'), findsNothing);
      expect(find.byType(CompleterInterventionScreen), findsNothing);

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets(
    'cloturer juste apres une frappe rapide n efface pas probleme/travaux '
    '(piege de course avec l anti-rebond)',
    (tester) async {
      final db = await _dbAvec(_intervention());

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Climatiseur en panne');
      await tester.enterText(find.byType(TextField).last, 'Filtre nettoye');
      await tester.pump();

      // Tape sur Cloturer bien avant les 400ms de l'anti-rebond : reproduit
      // le bug reel diagnostique le 2026-09-14 (intervention "Nissi Bat
      // Service", passee REALISEE avec probleme/travaux vides en base, cause
      // d'un 400 bloquant toute la synchro). Le budget de temps ci-dessous
      // (~300ms cumules) reste sous les 400ms pour garder l'anti-rebond en
      // attente jusqu'a la confirmation.
      // Pumps a duree fixe uniquement (jamais pumpAndSettle) : settle() ferait
      // avancer l'horloge simulee par pas de 100ms jusqu'a stabilisation et
      // declencherait lui-meme l'anti-rebond, masquant la regression testee.
      await tester.tap(find.byKey(const Key('boutonCloturer')));
      await tester.pump();
      // 250ms : duree par defaut de l'animation d'ouverture du bottom sheet
      // Material, necessaire pour qu'il finisse de glisser a l'ecran et
      // devienne cliquable (sinon tap() rate le widget, encore hors-cadre).
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Clôturer cette intervention ?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('boutonConfirmerCloture')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Laisse la tentative de synchro post-cloture (synchroniser(), via le
      // MockClient de _app()) vider sa chaine d'await successifs, sans
      // avancer davantage l'horloge simulee (toujours sous les 400ms).
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final intervention = await db.interventionDao.parId('i-1');
      expect(intervention!.statut, StatutIntervention.realisee);
      expect(intervention.problemeConstate, 'Climatiseur en panne');
      expect(intervention.travauxRealises, 'Filtre nettoye');

      await _videLeTimerDeFermeture(tester);
    },
  );

  testWidgets('Retour dans la modale annule la cloture', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
    ));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boutonCloturer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statut, StatutIntervention.planifiee);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('une intervention cloturee s affiche en lecture seule avec le bandeau de succes', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
      statutSync: StatutSync.local,
    ));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('Réalisée le'), findsOneWidget);
    expect(find.text('À SYNCHRONISER'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Clôturer'), findsNothing);

    final champs = tester.widgetList<TextField>(find.byType(TextField));
    expect(champs.every((c) => c.readOnly), isTrue);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche PHOTOS A SYNCHRONISER si la cloture est confirmee mais pas les photos', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
      statutSync: StatutSync.confirme,
    ));
    await _ajouterPhoto(db, categorie: CategoriePhoto.avant);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('PHOTOS À SYNCHRONISER'), findsOneWidget);
    expect(find.text('SYNCHRONISÉE'), findsNothing);
    expect(find.text('À SYNCHRONISER'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche PHOTO EN ECHEC quand une photo est definitivement en conflit', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
      statutSync: StatutSync.confirme,
    ));
    final idLocal = await _ajouterPhoto(db, categorie: CategoriePhoto.avant);
    await db.photoDao.marquerEnConflit(idLocal);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('PHOTO EN ÉCHEC'), findsOneWidget);
    expect(find.text('PHOTOS À SYNCHRONISER'), findsNothing);
    expect(find.text('SYNCHRONISÉE'), findsNothing);
    expect(find.text('À SYNCHRONISER'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('les sections photos demarrent a 0 / 2 avec un bouton Ajouter', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 2'), findsNWidgets(2));
    expect(find.byKey(const Key('ajouterPhoto-avant')), findsOneWidget);
    expect(find.byKey(const Key('ajouterPhoto-apres')), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('ajouter une photo avant via la modale l enregistre et met a jour le compteur', (tester) async {
    final db = await _dbAvec(_intervention());
    final stockageFaux = _PhotoStockageServiceFausse();

    await tester.pumpWidget(_app(db, photoStockage: stockageFaux));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('ajouterPhoto-avant')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ajouterPhoto-avant')));
    await tester.pumpAndSettle();

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir dans la galerie'), findsOneWidget);

    await tester.tap(find.byKey(const Key('optionCamera')));
    await tester.pumpAndSettle();

    expect(stockageFaux.compteur, 1);
    final photos = await db.photoDao.listerPourIntervention('i-1');
    expect(photos, hasLength(1));
    expect(photos.single.categorie, CategoriePhoto.avant);
    expect(photos.single.statutSync, StatutSync.local);
    expect(find.textContaining('1 / 2'), findsOneWidget);
    expect(find.textContaining('0 / 2'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('le bouton Ajouter disparait a 2 photos dans une categorie mais pas dans l autre', (tester) async {
    final db = await _dbAvec(_intervention());
    await _ajouterPhoto(db, categorie: CategoriePhoto.avant);
    await _ajouterPhoto(db, categorie: CategoriePhoto.avant);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 / 2'), findsOneWidget);
    expect(find.byKey(const Key('ajouterPhoto-avant')), findsNothing);
    expect(find.byKey(const Key('ajouterPhoto-apres')), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('supprimer une photo la retire et fait reapparaitre le bouton Ajouter', (tester) async {
    final db = await _dbAvec(_intervention());
    final idPhoto1 = await _ajouterPhoto(db, categorie: CategoriePhoto.avant);
    await _ajouterPhoto(db, categorie: CategoriePhoto.avant);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ajouterPhoto-avant')), findsNothing);

    await tester.ensureVisible(find.byKey(Key('supprimerPhoto-$idPhoto1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('supprimerPhoto-$idPhoto1')));
    await tester.pumpAndSettle();

    final photos = await db.photoDao.listerPourIntervention('i-1');
    expect(photos, hasLength(1));
    expect(find.textContaining('1 / 2'), findsOneWidget);
    expect(find.byKey(const Key('ajouterPhoto-avant')), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('une intervention cloturee affiche les photos en lecture seule sans Ajouter ni Supprimer', (tester) async {
    final db = await _dbAvec(_intervention(
      problemeConstate: 'Climatiseur en panne',
      travauxRealises: 'Filtre nettoye',
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
    ));
    await _ajouterPhoto(db, categorie: CategoriePhoto.avant);
    await _ajouterPhoto(db, categorie: CategoriePhoto.apres);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 2'), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byKey(const Key('ajouterPhoto-avant')), findsNothing);
    expect(find.byKey(const Key('ajouterPhoto-apres')), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });
}
