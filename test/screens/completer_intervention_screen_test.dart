import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/completer_intervention_screen.dart';
import 'package:sim_interventions/services/photo_stockage_service.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

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

Widget _app(
  AppDatabase db, {
  String idServeur = 'i-1',
  PhotoStockageService? photoStockage,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
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
