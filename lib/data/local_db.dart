import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/enums.dart';
import 'dao/intervention_dao.dart';
import 'dao/photo_dao.dart';

part 'local_db.g.dart';

/// Miroir local du modele Intervention (docs/ADR.md, socle commun) plus les
/// champs de synchronisation. Une intervention n'est jamais creee localement
/// dans le MVP : elle arrive uniquement par la synchro (pull).
class Interventions extends Table {
  TextColumn get idServeur => text()();
  TextColumn get nomClient => text()();
  TextColumn get adresse => text()();
  TextColumn get telephone1 => text()();
  TextColumn get telephone2 => text().nullable()();
  TextColumn get geolocalisation => text().nullable()();
  TextColumn get motifSignale => text().nullable()();
  DateTimeColumn get datePrevue => dateTime()();
  TextColumn get technicienId => text()();
  TextColumn get creeParId => text()();
  TextColumn get typeEquipement => textEnum<TypeEquipement>().nullable()();
  TextColumn get problemeConstate => text().nullable()();
  TextColumn get travauxRealises => text().nullable()();
  TextColumn get statut => textEnum<StatutIntervention>()();
  DateTimeColumn get dateRealisation => dateTime().nullable()();
  DateTimeColumn get creeLe => dateTime()();
  DateTimeColumn get misAJourLe => dateTime()();

  // Champs de synchronisation (US2.9, US2.11), sans equivalent serveur.
  TextColumn get statutSync => textEnum<StatutSync>()();
  DateTimeColumn get modifieLocalementLe => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {idServeur};
}

/// Miroir local du modele Photo. Contrairement a Intervention, une photo est
/// creee localement (le technicien la prend avant toute synchro) : idLocal
/// est la cle primaire locale, idServeur n'existe qu'apres confirmation.
class Photos extends Table {
  IntColumn get idLocal => integer().autoIncrement()();
  TextColumn get idServeur => text().nullable()();
  TextColumn get interventionIdLocal =>
      text().references(Interventions, #idServeur)();
  TextColumn get categorie => textEnum<CategoriePhoto>()();
  TextColumn get cheminLocal => text()();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
  TextColumn get statutSync => textEnum<StatutSync>()();
}

@DriftDatabase(
  tables: [Interventions, Photos],
  daos: [InterventionDao, PhotoDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] permet d'injecter une base en memoire dans les tests
  /// (`NativeDatabase.memory()`) ; en production, la connexion native
  /// `drift_flutter` est utilisee par defaut.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sim_interventions'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
