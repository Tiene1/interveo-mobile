import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/completer_intervention_screen.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

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

Widget _app(AppDatabase db, {String idServeur = 'i-1'}) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: CompleterInterventionScreen(idServeur: idServeur)),
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
}
