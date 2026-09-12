import 'package:drift/drift.dart';

import '../local_db.dart';

part 'intervention_dao.g.dart';

/// Acces de base a la table Interventions. La logique de synchronisation
/// (push/pull/conflit) vit dans sync_service.dart, pas ici.
@DriftAccessor(tables: [Interventions])
class InterventionDao extends DatabaseAccessor<AppDatabase>
    with _$InterventionDaoMixin {
  InterventionDao(super.db);

  Stream<List<Intervention>> watchToutes() => select(interventions).watch();

  Future<Intervention?> parId(String idServeur) =>
      (select(interventions)..where((i) => i.idServeur.equals(idServeur)))
          .getSingleOrNull();

  Future<void> upsert(InterventionsCompanion intervention) =>
      into(interventions).insertOnConflictUpdate(intervention);
}
