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

  Future<Intervention?> parId(String idServeur) => (select(
    interventions,
  )..where((i) => i.idServeur.equals(idServeur))).getSingleOrNull();

  /// US2.2/US2.3 : detail reactif d'une intervention (se met a jour si une
  /// synchro modifie la ligne pendant que l'ecran est ouvert).
  Stream<Intervention?> watchParId(String idServeur) => (select(
    interventions,
  )..where((i) => i.idServeur.equals(idServeur))).watchSingleOrNull();

  Future<void> upsert(InterventionsCompanion intervention) =>
      into(interventions).insertOnConflictUpdate(intervention);

  /// Le plus recent `misAJourLe` connu localement : sert de curseur `depuis`
  /// pour le prochain pull (le serveur trie deja par misAJourLe croissant).
  /// Null si la base locale est vide (premiere synchro : tout est demande).
  Future<DateTime?> derniereMiseAJour() async {
    final ligne =
        await (select(interventions)
              ..orderBy([(i) => OrderingTerm.desc(i.misAJourLe)])
              ..limit(1))
            .getSingleOrNull();
    return ligne?.misAJourLe;
  }

  /// US2.5/US2.6/US2.9 : saisie au fil de l'eau. Value.absent() (par defaut)
  /// laisse le champ correspondant inchange ; un seul champ est en general
  /// fourni a la fois (chaque textarea a son propre anti-rebond cote ecran).
  /// Marque la ligne LOCAL : elle devra etre poussee au serveur.
  Future<void> mettreAJourSaisie(
    String idServeur, {
    Value<String?> problemeConstate = const Value.absent(),
    Value<String?> travauxRealises = const Value.absent(),
  }) {
    return (update(
      interventions,
    )..where((i) => i.idServeur.equals(idServeur))).write(
      InterventionsCompanion(
        problemeConstate: problemeConstate,
        travauxRealises: travauxRealises,
        statutSync: const Value(StatutSync.local),
        modifieLocalementLe: Value(DateTime.now()),
      ),
    );
  }

  /// US2.10 : PLANIFIEE -> REALISEE, marquee LOCAL (a pousser). L'ecran passe
  /// en lecture seule des que le flux reactif renvoie ce nouveau statut.
  Future<void> cloturer(String idServeur, {required DateTime dateRealisation}) {
    return (update(
      interventions,
    )..where((i) => i.idServeur.equals(idServeur))).write(
      InterventionsCompanion(
        statut: const Value(StatutIntervention.realisee),
        dateRealisation: Value(dateRealisation),
        statutSync: const Value(StatutSync.local),
        modifieLocalementLe: Value(dateRealisation),
      ),
    );
  }
}
