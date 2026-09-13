import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../local_db.dart';

part 'intervention_dao.g.dart';

/// Acces de base a la table Interventions. La logique de synchronisation
/// (push/pull/conflit) vit dans sync_service.dart, pas ici.
@DriftAccessor(tables: [Interventions])
class InterventionDao extends DatabaseAccessor<AppDatabase>
    with _$InterventionDaoMixin {
  InterventionDao(super.db);

  Stream<List<Intervention>> watchToutes() => select(interventions).watch();

  /// US2.1 : interventions non annulees, triees par date et heure prevues.
  Stream<List<Intervention>> watchAttribuees() {
    return (select(interventions)
          ..where((i) => i.statut.equalsValue(StatutIntervention.annulee).not())
          ..orderBy([(i) => OrderingTerm.asc(i.datePrevue)]))
        .watch();
  }

  Future<Intervention?> parId(String idServeur) =>
      (select(interventions)..where((i) => i.idServeur.equals(idServeur)))
          .getSingleOrNull();

  Future<void> upsert(InterventionsCompanion intervention) =>
      into(interventions).insertOnConflictUpdate(intervention);

  /// Le plus recent `misAJourLe` connu localement : sert de curseur `depuis`
  /// pour le prochain pull (le serveur trie deja par misAJourLe croissant).
  /// Null si la base locale est vide (premiere synchro : tout est demande).
  Future<DateTime?> derniereMiseAJour() async {
    final ligne = await (select(interventions)
          ..orderBy([(i) => OrderingTerm.desc(i.misAJourLe)])
          ..limit(1))
        .getSingleOrNull();
    return ligne?.misAJourLe;
  }
}
