import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/mes_interventions_screen.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

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

Widget _app(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
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
}
