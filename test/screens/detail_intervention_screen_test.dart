import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';
import 'package:sim_interventions/screens/completer_intervention_screen.dart';
import 'package:sim_interventions/screens/detail_intervention_screen.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

InterventionsCompanion _intervention({
  String idServeur = 'i-1',
  String nomClient = 'Hotel Ivoire',
  String? motifSignale,
  String? telephone2,
  String? geolocalisation,
  StatutIntervention statut = StatutIntervention.planifiee,
  DateTime? dateRealisation,
}) {
  final datePrevue = DateTime(2026, 9, 14, 9);
  return InterventionsCompanion.insert(
    idServeur: idServeur,
    nomClient: nomClient,
    adresse: 'Boulevard Hassan II, Cocody',
    telephone1: '0102030405',
    telephone2: Value(telephone2),
    geolocalisation: Value(geolocalisation),
    motifSignale: Value(motifSignale),
    datePrevue: datePrevue,
    technicienId: 'tech-1',
    creeParId: 'directeur-1',
    statut: statut,
    dateRealisation: Value(dateRealisation),
    creeLe: datePrevue,
    misAJourLe: datePrevue,
    statutSync: StatutSync.confirme,
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
    child: MaterialApp(home: DetailInterventionScreen(idServeur: idServeur)),
  );
}

/// Drift programme un timer interne (duree 0) quand une requete .watch()
/// se ferme (issue connue simolus3/drift#3323).
Future<void> _videLeTimerDeFermeture(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets('affiche le client, la date et le motif renseigne', (tester) async {
    final db = await _dbAvec(_intervention(motifSignale: 'Climatiseur en panne'));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Hotel Ivoire'), findsOneWidget);
    expect(find.text('14/09/2026 · 09:00'), findsOneWidget);
    expect(find.text('Climatiseur en panne'), findsOneWidget);
    expect(find.text('Planifiée'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche "non renseigne" quand le motif est absent', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('— non renseigné —'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche Realisee et la date de cloture quand pertinent', (tester) async {
    final db = await _dbAvec(_intervention(
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
    ));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Réalisée'), findsOneWidget);
    expect(find.textContaining('Clôturée'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('Appeler le 2 absent si telephone2 est vide', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Appeler'), findsOneWidget);
    expect(find.text('Appeler le 2'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('Appeler le 2 present si telephone2 est renseigne', (tester) async {
    final db = await _dbAvec(_intervention(telephone2: '0708091011'));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Appeler le 2'), findsOneWidget);
    expect(find.text('0708091011'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('Itineraire absent si geolocalisation est vide', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Itinéraire Google Maps'), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('Itineraire present si geolocalisation est renseignee', (tester) async {
    final db = await _dbAvec(_intervention(geolocalisation: '5.359,-3.996'));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Itinéraire Google Maps'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('affiche un message si l intervention est introuvable', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(_app(db, idServeur: 'inconnu'));
    await tester.pumpAndSettle();

    expect(find.text('Intervention introuvable.'), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('le bouton retour depile l ecran', (tester) async {
    final db = await _dbAvec(_intervention());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DetailInterventionScreen(idServeur: 'i-1')),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailInterventionScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(DetailInterventionScreen), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets("le bouton du bas ouvre Completer, libelle selon le statut", (tester) async {
    final dbPlanifiee = await _dbAvec(_intervention());

    await tester.pumpWidget(_app(dbPlanifiee));
    await tester.pumpAndSettle();

    expect(find.text("Compléter l'intervention"), findsOneWidget);
    expect(find.text('Voir le compte rendu'), findsNothing);

    await tester.tap(find.text("Compléter l'intervention"));
    await tester.pumpAndSettle();

    expect(find.byType(CompleterInterventionScreen), findsOneWidget);

    await _videLeTimerDeFermeture(tester);
  });

  testWidgets('le bouton du bas affiche Voir le compte rendu si Realisee', (tester) async {
    final db = await _dbAvec(_intervention(
      statut: StatutIntervention.realisee,
      dateRealisation: DateTime(2026, 9, 14, 15, 30),
    ));

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    expect(find.text('Voir le compte rendu'), findsOneWidget);
    expect(find.text("Compléter l'intervention"), findsNothing);

    await _videLeTimerDeFermeture(tester);
  });
}
